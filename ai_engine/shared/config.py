"""
Configurações centralizadas do AI Engine.
Carrega variáveis de ambiente com valores padrão seguros.
"""
import os
from functools import lru_cache
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    # RabbitMQ
    rabbitmq_host: str = "localhost"
    rabbitmq_port: int = 5672
    rabbitmq_user: str = "guest"
    rabbitmq_pass: str = "guest"
    rabbitmq_queue: str = "ai_tasks_queue"
    rabbitmq_dlq: str = "ai_tasks_dlq"
    rabbitmq_dlx: str = "ai_tasks_dlx"
    
    # Redis (para idempotência e checkpoints)
    redis_host: str = "localhost"
    redis_port: int = 6379
    redis_db: int = 0
    redis_password: Optional[str] = None
    
    # Postgres AI (para configs multi-tenant e RAG)
    postgres_ai_host: str = "localhost"
    postgres_ai_port: int = 5433
    postgres_ai_user: str = "langfuse"
    postgres_ai_pass: str = "langfuse"
    postgres_ai_db: str = "ai_engine"
    
    # Langfuse (observabilidade)
    langfuse_public_key: Optional[str] = None
    langfuse_secret_key: Optional[str] = None
    langfuse_host: str = "http://localhost:3333"
    
    # OpenAI
    openai_api_key: Optional[str] = None
    openai_model: str = "gpt-3.5-turbo"
    openai_temperature: float = 0.7
    
    # Chatwoot API (para enviar respostas)
    chatwoot_base_url: str = "http://localhost:3000"
    chatwoot_api_token: Optional[str] = None
    
    # Retry/DLQ
    max_retry_attempts: int = 3
    retry_delay_base_seconds: int = 5
    
    # Idempotência
    idempotency_ttl_seconds: int = 3600  # 1 hora
    
    # Feature Flags
    enable_rag: bool = False
    enable_memory: bool = False
    enable_multi_tenant_prompts: bool = True
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    """Retorna instância cacheada das configurações."""
    return Settings()
