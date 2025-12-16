"""
Schemas de payload interno para comunicação Gateway -> Queue -> Worker.
Define contratos únicos com validação via Pydantic.
"""
from datetime import datetime
from typing import Optional, Any
from pydantic import BaseModel, Field
from enum import Enum


class MessageType(str, Enum):
    INCOMING = "incoming"
    OUTGOING = "outgoing"
    ACTIVITY = "activity"
    TEMPLATE = "template"


class SenderType(str, Enum):
    USER = "User"
    CONTACT = "Contact"
    AGENT_BOT = "AgentBot"


class AgentBotConfig(BaseModel):
    """Configuração do AgentBot que disparou o evento."""
    agent_id: int
    agent_name: str
    context_prompt: Optional[str] = None
    ai_agent_type: Optional[str] = None
    response_mode: Optional[str] = "auto_respond"
    bot_config: Optional[dict] = None
    outgoing_url: Optional[str] = None


class AccountInfo(BaseModel):
    """Informações da conta/tenant."""
    id: int
    name: Optional[str] = None


class ConversationInfo(BaseModel):
    """Informações da conversa."""
    id: int
    display_id: Optional[int] = None
    status: Optional[str] = None
    assignee_id: Optional[int] = None


class InboxInfo(BaseModel):
    """Informações da inbox."""
    id: int
    name: Optional[str] = None
    channel_type: Optional[str] = None


class SenderInfo(BaseModel):
    """Informações do remetente."""
    id: int
    name: Optional[str] = None
    email: Optional[str] = None
    type: Optional[SenderType] = None


class AITaskPayload(BaseModel):
    """
    Schema interno único para tarefas na fila.
    Usado para comunicação Gateway -> RabbitMQ -> Worker.
    """
    # Identificadores únicos (para idempotência e rastreio)
    correlation_id: str = Field(..., description="ID único da mensagem (message.id do Chatwoot)")
    tenant_id: int = Field(..., description="ID da conta (account.id)")
    conversation_id: int = Field(..., description="ID da conversa")
    inbox_id: int = Field(..., description="ID da inbox")
    
    # Conteúdo da mensagem
    content: str = Field(..., description="Texto da mensagem do usuário")
    message_type: MessageType = Field(..., description="Tipo da mensagem")
    
    # Informações do remetente
    sender_id: Optional[int] = None
    sender_type: Optional[SenderType] = None
    sender_name: Optional[str] = None
    
    # Configuração do AgentBot
    agent_bot: Optional[AgentBotConfig] = None
    
    # Metadados
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    retry_count: int = Field(default=0, description="Contador de tentativas")
    
    # Dados brutos (para debugging/extensibilidade)
    raw_payload: Optional[dict] = None

    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class AITaskResult(BaseModel):
    """Resultado do processamento de uma tarefa."""
    correlation_id: str
    tenant_id: int
    conversation_id: int
    success: bool
    response_content: Optional[str] = None
    error_message: Optional[str] = None
    processing_time_ms: Optional[float] = None
    langfuse_trace_id: Optional[str] = None


class ChatwootMessageRequest(BaseModel):
    """Request para enviar mensagem ao Chatwoot via API."""
    content: str
    message_type: str = "outgoing"
    private: bool = False
    content_attributes: Optional[dict] = None
