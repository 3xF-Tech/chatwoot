"""
API Gateway do AI Engine.
Recebe webhooks do Chatwoot, valida, filtra e enfileira para processamento.
"""
import json
import os
import sys
import logging
from datetime import datetime
from typing import Optional

import pika
from fastapi import FastAPI, Request, HTTPException, Header
from pydantic import BaseModel
from dotenv import load_dotenv

# Adiciona o diretório pai ao path para imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.config import get_settings
from shared.schemas import AITaskPayload, MessageType, SenderType, AgentBotConfig
from shared.constants import (
    IGNORED_SENDER_TYPES, 
    ALLOWED_EVENTS,
    MESSAGE_TYPE_INCOMING,
    MESSAGE_TYPE_OUTGOING,
    MESSAGE_TYPE_ACTIVITY
)
from shared.services.idempotency import get_idempotency_service

load_dotenv()

# Configuração de Logs
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - [%(levelname)s] - %(name)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Chatwoot AI Gateway",
    description="Gateway para processamento de mensagens com IA",
    version="0.2.0"
)

settings = get_settings()


def get_rabbitmq_connection():
    """Cria conexão com RabbitMQ."""
    credentials = pika.PlainCredentials(
        settings.rabbitmq_user,
        settings.rabbitmq_pass
    )
    return pika.BlockingConnection(
        pika.ConnectionParameters(
            host=settings.rabbitmq_host,
            port=settings.rabbitmq_port,
            credentials=credentials
        )
    )


def setup_queues(channel):
    """Configura filas com DLQ."""
    # Declara exchange para DLQ
    channel.exchange_declare(
        exchange=settings.rabbitmq_dlx,
        exchange_type='direct',
        durable=True
    )
    
    # Declara DLQ
    channel.queue_declare(
        queue=settings.rabbitmq_dlq,
        durable=True
    )
    channel.queue_bind(
        queue=settings.rabbitmq_dlq,
        exchange=settings.rabbitmq_dlx,
        routing_key=settings.rabbitmq_dlq
    )
    
    # Declara fila principal com DLX configurado
    channel.queue_declare(
        queue=settings.rabbitmq_queue,
        durable=True,
        arguments={
            'x-dead-letter-exchange': settings.rabbitmq_dlx,
            'x-dead-letter-routing-key': settings.rabbitmq_dlq
        }
    )


def publish_to_queue(task: AITaskPayload) -> bool:
    """
    Publica tarefa na fila RabbitMQ.
    
    Args:
        task: Payload da tarefa
        
    Returns:
        True se publicou com sucesso
    """
    try:
        connection = get_rabbitmq_connection()
        channel = connection.channel()
        
        setup_queues(channel)
        
        # Serializa com suporte a datetime
        message_body = task.model_dump_json()
        
        channel.basic_publish(
            exchange='',
            routing_key=settings.rabbitmq_queue,
            body=message_body,
            properties=pika.BasicProperties(
                delivery_mode=2,  # Persistente
                content_type='application/json',
                correlation_id=task.correlation_id,
                timestamp=int(datetime.utcnow().timestamp())
            )
        )
        
        connection.close()
        logger.info(f"Tarefa enfileirada: correlation_id={task.correlation_id}")
        return True
        
    except Exception as e:
        logger.error(f"Erro ao publicar na fila: {e}")
        return False


def extract_sender_type(payload: dict) -> Optional[SenderType]:
    """Extrai tipo do remetente do payload."""
    sender = payload.get("sender", {})
    if not sender:
        return None
    
    # O Chatwoot pode enviar 'type' diretamente ou inferimos do contexto
    sender_type = sender.get("type")
    if sender_type:
        if sender_type in ["AgentBot", "agent_bot"]:
            return SenderType.AGENT_BOT
        elif sender_type == "User":
            return SenderType.USER
        elif sender_type == "Contact":
            return SenderType.CONTACT
    
    return SenderType.CONTACT  # Default para mensagens incoming


def extract_message_type(payload: dict) -> MessageType:
    """Extrai tipo da mensagem do payload."""
    msg_type = payload.get("message_type")
    
    if msg_type == MESSAGE_TYPE_INCOMING or msg_type == "incoming":
        return MessageType.INCOMING
    elif msg_type == MESSAGE_TYPE_OUTGOING or msg_type == "outgoing":
        return MessageType.OUTGOING
    elif msg_type == "activity" or msg_type == MESSAGE_TYPE_ACTIVITY:
        return MessageType.ACTIVITY
    elif msg_type == "template" or msg_type == 3:
        return MessageType.TEMPLATE
    
    return MessageType.INCOMING  # Default


def extract_agent_bot_config(payload: dict) -> Optional[AgentBotConfig]:
    """Extrai configuração do AgentBot do payload."""
    agent_bot = payload.get("agent_bot")
    if not agent_bot:
        return None
    
    return AgentBotConfig(
        agent_id=agent_bot.get("agent_id"),
        agent_name=agent_bot.get("agent_name", ""),
        context_prompt=agent_bot.get("context_prompt"),
        ai_agent_type=agent_bot.get("ai_agent_type"),
        response_mode=agent_bot.get("response_mode", "auto_respond"),
        bot_config=agent_bot.get("bot_config"),
        outgoing_url=agent_bot.get("outgoing_url")
    )


def should_process_message(payload: dict) -> tuple[bool, str]:
    """
    Verifica se a mensagem deve ser processada.
    
    Returns:
        (should_process, reason)
    """
    # Filtro 1: Evento correto
    event = payload.get("event")
    if event not in ALLOWED_EVENTS:
        return False, f"Evento ignorado: {event}"
    
    # Filtro 2: Mensagem privada
    if payload.get("private", False):
        return False, "Nota privada ignorada"
    
    # Filtro 3: Conteúdo vazio
    content = payload.get("content", "")
    if not content or not content.strip():
        return False, "Conteudo vazio ignorado"
    
    # Filtro 4: Tipo de mensagem (só incoming)
    message_type = payload.get("message_type")
    if message_type == MESSAGE_TYPE_OUTGOING or message_type == "outgoing":
        return False, "Mensagem outgoing ignorada"
    
    if message_type == MESSAGE_TYPE_ACTIVITY or message_type == "activity":
        return False, "Mensagem de atividade ignorada"
    
    # Filtro 5: Anti-loop - mensagens do próprio bot
    sender = payload.get("sender", {})
    sender_type = sender.get("type", "")
    
    if sender_type in IGNORED_SENDER_TYPES:
        return False, f"Mensagem de {sender_type} ignorada (anti-loop)"
    
    # Filtro 6: Verificar se há AgentBot configurado
    agent_bot = payload.get("agent_bot")
    if not agent_bot:
        return False, "Sem AgentBot configurado"
    
    return True, "OK"


@app.post("/chatwoot-hook")
async def chatwoot_webhook(request: Request):
    """
    Endpoint principal para webhooks do Chatwoot.
    
    Fluxo:
    1. Valida evento e filtros
    2. Verifica idempotência
    3. Normaliza payload
    4. Enfileira para processamento
    """
    try:
        payload = await request.json()
        
        # Log do evento recebido
        event = payload.get("event", "unknown")
        message_id = payload.get("id", "unknown")
        logger.info(f"Webhook recebido: event={event}, message_id={message_id}")
        
        # Aplica filtros
        should_process, reason = should_process_message(payload)
        if not should_process:
            logger.debug(f"Mensagem filtrada: {reason}")
            return {"status": "ignored", "reason": reason}
        
        # Extrai correlation_id
        correlation_id = str(payload.get("id"))
        
        # Verifica idempotência
        idempotency = get_idempotency_service()
        if idempotency.is_processed(correlation_id):
            logger.info(f"Mensagem duplicada ignorada: {correlation_id}")
            return {"status": "duplicate", "correlation_id": correlation_id}
        
        # Tenta adquirir lock
        if not idempotency.mark_as_processing(correlation_id):
            logger.info(f"Mensagem já em processamento: {correlation_id}")
            return {"status": "processing", "correlation_id": correlation_id}
        
        # Monta payload interno
        account = payload.get("account", {})
        conversation = payload.get("conversation", {})
        inbox = payload.get("inbox", {})
        sender = payload.get("sender", {})
        
        task = AITaskPayload(
            correlation_id=correlation_id,
            tenant_id=account.get("id", 0),
            conversation_id=conversation.get("id", 0),
            inbox_id=inbox.get("id", 0),
            content=payload.get("content", ""),
            message_type=extract_message_type(payload),
            sender_id=sender.get("id"),
            sender_type=extract_sender_type(payload),
            sender_name=sender.get("name"),
            agent_bot=extract_agent_bot_config(payload),
            timestamp=datetime.utcnow(),
            retry_count=0,
            raw_payload=payload
        )
        
        # Publica na fila
        success = publish_to_queue(task)
        
        if not success:
            idempotency.release_lock(correlation_id)
            raise HTTPException(status_code=500, detail="Broker indisponível")
        
        return {
            "status": "queued",
            "correlation_id": correlation_id,
            "tenant_id": task.tenant_id,
            "conversation_id": task.conversation_id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro no processamento: {e}", exc_info=True)
        return {"status": "error", "detail": str(e)}


@app.get("/health")
def health_check():
    """Endpoint de health check."""
    return {
        "status": "ok",
        "service": "ai-gateway",
        "version": "0.2.0"
    }


@app.get("/ready")
def readiness_check():
    """Verifica se o serviço está pronto (conexões ok)."""
    checks = {
        "rabbitmq": False,
        "redis": False
    }
    
    # Verifica RabbitMQ
    try:
        connection = get_rabbitmq_connection()
        connection.close()
        checks["rabbitmq"] = True
    except Exception as e:
        logger.warning(f"RabbitMQ não disponível: {e}")
    
    # Verifica Redis
    try:
        idempotency = get_idempotency_service()
        if idempotency.client:
            idempotency.client.ping()
            checks["redis"] = True
    except Exception as e:
        logger.warning(f"Redis não disponível: {e}")
    
    all_ok = all(checks.values())
    
    return {
        "status": "ready" if all_ok else "degraded",
        "checks": checks
    }
