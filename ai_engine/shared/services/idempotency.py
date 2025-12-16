"""
Serviço de idempotência usando Redis.
Previne processamento duplicado de mensagens.
"""
import redis
import logging
from typing import Optional
from ..config import get_settings

logger = logging.getLogger(__name__)


class IdempotencyService:
    """
    Gerencia idempotência de processamento de mensagens.
    Usa Redis para armazenar correlation_ids já processados.
    """
    
    def __init__(self):
        self.settings = get_settings()
        self._client: Optional[redis.Redis] = None
        self._prefix = "ai_engine:processed:"
    
    @property
    def client(self) -> redis.Redis:
        """Conexão lazy com Redis."""
        if self._client is None:
            try:
                self._client = redis.Redis(
                    host=self.settings.redis_host,
                    port=self.settings.redis_port,
                    db=self.settings.redis_db,
                    password=self.settings.redis_password,
                    decode_responses=True,
                    socket_connect_timeout=5,
                    socket_timeout=5
                )
                self._client.ping()
                logger.info("Redis conectado com sucesso")
            except redis.ConnectionError as e:
                logger.warning(f"Redis não disponível: {e}. Idempotência desabilitada.")
                self._client = None
        return self._client
    
    def is_processed(self, correlation_id: str) -> bool:
        """
        Verifica se uma mensagem já foi processada.
        
        Args:
            correlation_id: ID único da mensagem
            
        Returns:
            True se já foi processada, False caso contrário
        """
        if not self.client:
            return False
        
        try:
            key = f"{self._prefix}{correlation_id}"
            return self.client.exists(key) > 0
        except Exception as e:
            logger.error(f"Erro ao verificar idempotência: {e}")
            return False
    
    def mark_as_processed(self, correlation_id: str, result: str = "ok") -> bool:
        """
        Marca uma mensagem como processada.
        
        Args:
            correlation_id: ID único da mensagem
            result: Resultado do processamento (para debugging)
            
        Returns:
            True se marcou com sucesso
        """
        if not self.client:
            return False
        
        try:
            key = f"{self._prefix}{correlation_id}"
            self.client.setex(
                key,
                self.settings.idempotency_ttl_seconds,
                result
            )
            logger.debug(f"Mensagem marcada como processada: {correlation_id}")
            return True
        except Exception as e:
            logger.error(f"Erro ao marcar como processada: {e}")
            return False
    
    def mark_as_processing(self, correlation_id: str, ttl_seconds: int = 300) -> bool:
        """
        Marca uma mensagem como em processamento (lock).
        Usa SETNX para garantir atomicidade.
        
        Args:
            correlation_id: ID único da mensagem
            ttl_seconds: TTL do lock (default: 5 minutos)
            
        Returns:
            True se conseguiu o lock, False se já está em processamento
        """
        if not self.client:
            return True  # Se Redis não disponível, permite processamento
        
        try:
            key = f"{self._prefix}lock:{correlation_id}"
            acquired = self.client.set(key, "processing", nx=True, ex=ttl_seconds)
            return acquired is not None
        except Exception as e:
            logger.error(f"Erro ao adquirir lock: {e}")
            return True  # Em caso de erro, permite processamento
    
    def release_lock(self, correlation_id: str) -> bool:
        """Remove o lock de processamento."""
        if not self.client:
            return True
        
        try:
            key = f"{self._prefix}lock:{correlation_id}"
            self.client.delete(key)
            return True
        except Exception as e:
            logger.error(f"Erro ao liberar lock: {e}")
            return False
    
    def get_processing_status(self, correlation_id: str) -> Optional[str]:
        """Retorna o status de processamento de uma mensagem."""
        if not self.client:
            return None
        
        try:
            key = f"{self._prefix}{correlation_id}"
            return self.client.get(key)
        except Exception as e:
            logger.error(f"Erro ao obter status: {e}")
            return None


# Singleton
_idempotency_service: Optional[IdempotencyService] = None


def get_idempotency_service() -> IdempotencyService:
    """Retorna instância singleton do serviço."""
    global _idempotency_service
    if _idempotency_service is None:
        _idempotency_service = IdempotencyService()
    return _idempotency_service
