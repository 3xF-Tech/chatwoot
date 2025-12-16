"""
Worker do AI Engine.
Consome tarefas da fila, executa o agente e envia resposta ao Chatwoot.
"""
import json
import os
import sys
import time
import logging
from datetime import datetime

import pika
from dotenv import load_dotenv
from langchain_core.messages import HumanMessage
from langfuse.decorators import observe, langfuse_context

# Adiciona o diretório pai ao path para imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.config import get_settings
from shared.schemas import AITaskPayload, AITaskResult
from shared.constants import DEFAULT_PROMPTS, RESPONSE_MODE_AUTO, RESPONSE_MODE_ASSIST
from shared.services.idempotency import get_idempotency_service
from shared.services.chatwoot_client import get_chatwoot_client

# Import do Grafo
try:
    from worker.agent_graph import create_agent_graph
except ImportError:
    from agent_graph import create_agent_graph

load_dotenv()

# Configuração de Logs
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - [%(levelname)s] - %(name)s - %(message)s'
)
logger = logging.getLogger(__name__)

settings = get_settings()


def get_system_prompt(task: AITaskPayload) -> str:
    """
    Obtém o system prompt para a tarefa.
    Prioridade: agent_bot.context_prompt > DEFAULT_PROMPTS[ai_agent_type] > DEFAULT_PROMPTS['assistant']
    """
    if task.agent_bot and task.agent_bot.context_prompt:
        return task.agent_bot.context_prompt
    
    ai_agent_type = task.agent_bot.ai_agent_type if task.agent_bot else None
    if ai_agent_type and ai_agent_type in DEFAULT_PROMPTS:
        return DEFAULT_PROMPTS[ai_agent_type]
    
    return DEFAULT_PROMPTS.get("assistant", "Voce e um assistente virtual.")


def should_send_response(task: AITaskPayload) -> bool:
    """Verifica se deve enviar resposta automaticamente baseado no response_mode."""
    if not task.agent_bot:
        return True
    
    response_mode = task.agent_bot.response_mode
    return response_mode in [RESPONSE_MODE_AUTO, None, "auto_respond"]


def send_response_to_chatwoot(task: AITaskPayload, response_content: str) -> bool:
    """
    Envia a resposta do agente para o Chatwoot.
    
    Args:
        task: Tarefa original
        response_content: Conteudo da resposta
        
    Returns:
        True se enviou com sucesso
    """
    if not should_send_response(task):
        logger.info(f"Response mode '{task.agent_bot.response_mode}' - nao enviando resposta automatica")
        return True
    
    try:
        client = get_chatwoot_client()
        
        # Determina se e nota privada (assist_agent) ou publica (auto_respond)
        is_private = task.agent_bot and task.agent_bot.response_mode == RESPONSE_MODE_ASSIST
        
        result = client.send_message(
            account_id=task.tenant_id,
            conversation_id=task.conversation_id,
            content=response_content,
            private=is_private
        )
        
        logger.info(f"Resposta enviada ao Chatwoot: message_id={result.get('id')}")
        return True
        
    except Exception as e:
        logger.error(f"Erro ao enviar resposta ao Chatwoot: {e}")
        raise


@observe(name="processamento_agente")
def processar_mensagem(task: AITaskPayload) -> AITaskResult:
    """
    Processa uma tarefa da fila.
    
    Args:
        task: Payload da tarefa
        
    Returns:
        Resultado do processamento
    """
    start_time = datetime.utcnow()
    
    # Configura o contexto do Langfuse
    langfuse_context.update_current_trace(
        user_id=str(task.tenant_id),
        session_id=str(task.conversation_id),
        tags=["ai-engine-v0.2", f"tenant-{task.tenant_id}"],
        metadata={
            "correlation_id": task.correlation_id,
            "inbox_id": task.inbox_id,
            "agent_bot_id": task.agent_bot.agent_id if task.agent_bot else None,
            "ai_agent_type": task.agent_bot.ai_agent_type if task.agent_bot else None
        }
    )

    logger.info(
        f"[Worker] Processando: correlation_id={task.correlation_id}, "
        f"tenant={task.tenant_id}, conversation={task.conversation_id}"
    )
    
    try:
        # Obtém system prompt
        system_prompt = get_system_prompt(task)
        
        # Cria o grafo com o prompt customizado
        agent_app = create_agent_graph(system_prompt=system_prompt)
        
        inputs = {
            "messages": [HumanMessage(content=task.content)],
            "tenant_id": str(task.tenant_id)
        }
        
        # Executa o Grafo
        resultado = agent_app.invoke(inputs)
        
        # Extrai a resposta
        response_content = resultado["messages"][-1].content
        
        logger.info(f"[Worker] Resposta gerada: {response_content[:100]}...")
        
        # Envia resposta ao Chatwoot
        send_response_to_chatwoot(task, response_content)
        
        # Calcula tempo de processamento
        processing_time = (datetime.utcnow() - start_time).total_seconds() * 1000
        
        return AITaskResult(
            correlation_id=task.correlation_id,
            tenant_id=task.tenant_id,
            conversation_id=task.conversation_id,
            success=True,
            response_content=response_content,
            processing_time_ms=processing_time,
            langfuse_trace_id=langfuse_context.get_current_trace_id()
        )

    except Exception as e:
        logger.error(f"[Worker] Erro ao processar: {e}", exc_info=True)
        
        processing_time = (datetime.utcnow() - start_time).total_seconds() * 1000
        
        return AITaskResult(
            correlation_id=task.correlation_id,
            tenant_id=task.tenant_id,
            conversation_id=task.conversation_id,
            success=False,
            error_message=str(e),
            processing_time_ms=processing_time
        )


def handle_retry(task: AITaskPayload, channel, method) -> bool:
    """
    Gerencia retry de tarefas com falha.
    
    Args:
        task: Tarefa que falhou
        channel: Canal RabbitMQ
        method: Metodo de entrega
        
    Returns:
        True se deve fazer retry, False se excedeu tentativas (vai para DLQ)
    """
    task.retry_count += 1
    
    if task.retry_count >= settings.max_retry_attempts:
        logger.warning(
            f"[Worker] Max retries excedido para {task.correlation_id}. "
            f"Enviando para DLQ."
        )
        # Rejeita sem requeue - vai para DLQ automaticamente
        channel.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
        return False
    
    # Calcula delay exponencial
    delay_seconds = settings.retry_delay_base_seconds * (2 ** (task.retry_count - 1))
    logger.info(
        f"[Worker] Retry {task.retry_count}/{settings.max_retry_attempts} "
        f"para {task.correlation_id} em {delay_seconds}s"
    )
    
    # Aguarda antes de republicar
    time.sleep(delay_seconds)
    
    # Republica na fila
    channel.basic_publish(
        exchange='',
        routing_key=settings.rabbitmq_queue,
        body=task.model_dump_json(),
        properties=pika.BasicProperties(
            delivery_mode=2,
            content_type='application/json',
            correlation_id=task.correlation_id
        )
    )
    
    # Ack a mensagem original
    channel.basic_ack(delivery_tag=method.delivery_tag)
    return True


def callback(ch, method, properties, body):
    """Callback para processar mensagens da fila."""
    correlation_id = properties.correlation_id or "unknown"
    
    try:
        # Parse do payload
        dados = json.loads(body)
        task = AITaskPayload(**dados)
        
        # Processa a mensagem
        result = processar_mensagem(task)
        
        # Flush Langfuse antes do Ack
        langfuse_context.flush()
        
        if result.success:
            # Marca como processada e faz Ack
            idempotency = get_idempotency_service()
            idempotency.mark_as_processed(task.correlation_id, "success")
            ch.basic_ack(delivery_tag=method.delivery_tag)
            logger.info(f"[Worker] Tarefa concluida: {task.correlation_id}")
        else:
            # Tenta retry
            handle_retry(task, ch, method)
            
    except json.JSONDecodeError as e:
        logger.error(f"[Worker] Payload invalido: {e}")
        # Rejeita sem requeue - vai para DLQ
        ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
        
    except Exception as e:
        logger.error(f"[Worker] Erro fatal: {e}", exc_info=True)
        # Tenta extrair task para retry
        try:
            dados = json.loads(body)
            task = AITaskPayload(**dados)
            handle_retry(task, ch, method)
        except Exception:
            # Se nao conseguir nem parsear, rejeita
            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)


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


def main():
    """Loop principal do worker."""
    logger.info("[Worker] Inicializando AI Engine Worker v0.2.0...")
    logger.info(f"[Worker] Fila: {settings.rabbitmq_queue}")
    logger.info(f"[Worker] DLQ: {settings.rabbitmq_dlq}")
    logger.info(f"[Worker] Max retries: {settings.max_retry_attempts}")
    
    while True:
        try:
            credentials = pika.PlainCredentials(
                settings.rabbitmq_user,
                settings.rabbitmq_pass
            )
            connection = pika.BlockingConnection(
                pika.ConnectionParameters(
                    host=settings.rabbitmq_host,
                    port=settings.rabbitmq_port,
                    credentials=credentials,
                    heartbeat=600,
                    blocked_connection_timeout=300
                )
            )
            channel = connection.channel()
            
            setup_queues(channel)
            
            channel.basic_qos(prefetch_count=1)
            channel.basic_consume(
                queue=settings.rabbitmq_queue,
                on_message_callback=callback
            )
            
            logger.info("[Worker] Aguardando tarefas...")
            channel.start_consuming()
            
        except pika.exceptions.AMQPConnectionError as e:
            logger.error(f"[Worker] Erro de conexao RabbitMQ: {e}")
            time.sleep(5)
        except KeyboardInterrupt:
            logger.info("[Worker] Encerrando...")
            break
        except Exception as e:
            logger.error(f"[Worker] Erro inesperado: {e}", exc_info=True)
            time.sleep(5)


if __name__ == "__main__":
    main()
