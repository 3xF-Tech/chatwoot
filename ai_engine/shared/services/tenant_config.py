"""
Serviço de configuração multi-tenant.
Gerencia prompts e configurações customizadas por tenant/account.
"""
import logging
from typing import Optional, Dict, Any
from dataclasses import dataclass, field
from ..config import get_settings
from ..constants import DEFAULT_PROMPTS

logger = logging.getLogger(__name__)


@dataclass
class TenantConfig:
    """Configuração de um tenant."""
    tenant_id: int
    system_prompt: Optional[str] = None
    ai_agent_type: Optional[str] = None
    persona_name: Optional[str] = None
    persona_style: Optional[str] = None
    business_hours: Optional[Dict[str, Any]] = None
    rag_enabled: bool = False
    memory_enabled: bool = False
    max_tokens: int = 2000
    temperature: float = 0.7
    custom_tools: Optional[list] = None
    metadata: Optional[Dict[str, Any]] = field(default_factory=dict)


class TenantConfigService:
    """
    Serviço para gerenciar configurações de tenants.
    
    Atualmente usa cache em memória. Futuramente integrará com Postgres.
    """
    
    def __init__(self):
        self.settings = get_settings()
        self._cache: Dict[int, TenantConfig] = {}
    
    def get_config(self, tenant_id: int, agent_bot_config: Optional[Dict] = None) -> TenantConfig:
        """
        Obtém configuração de um tenant.
        
        Prioridade:
        1. Cache em memória
        2. Configuração do AgentBot (se fornecida)
        3. Configuração padrão
        """
        if tenant_id in self._cache:
            return self._cache[tenant_id]
        
        config = self._build_config_from_agent_bot(tenant_id, agent_bot_config)
        self._cache[tenant_id] = config
        
        return config
    
    def _build_config_from_agent_bot(
        self, 
        tenant_id: int, 
        agent_bot_config: Optional[Dict]
    ) -> TenantConfig:
        """Constrói configuração a partir do AgentBot."""
        
        if not agent_bot_config:
            return TenantConfig(
                tenant_id=tenant_id,
                system_prompt=DEFAULT_PROMPTS.get("assistant")
            )
        
        ai_agent_type = agent_bot_config.get("ai_agent_type", "assistant")
        
        system_prompt = agent_bot_config.get("context_prompt")
        if not system_prompt:
            system_prompt = DEFAULT_PROMPTS.get(ai_agent_type, DEFAULT_PROMPTS["assistant"])
        
        bot_config = agent_bot_config.get("bot_config", {}) or {}
        
        return TenantConfig(
            tenant_id=tenant_id,
            system_prompt=system_prompt,
            ai_agent_type=ai_agent_type,
            persona_name=agent_bot_config.get("agent_name"),
            rag_enabled=bot_config.get("rag_enabled", False),
            memory_enabled=bot_config.get("memory_enabled", False),
            max_tokens=bot_config.get("max_tokens", 2000),
            temperature=bot_config.get("temperature", 0.7),
            metadata={
                "agent_id": agent_bot_config.get("agent_id"),
                "response_mode": agent_bot_config.get("response_mode")
            }
        )
    
    def get_system_prompt(self, tenant_id: int, agent_bot_config: Optional[Dict] = None) -> str:
        """Atalho para obter apenas o system prompt."""
        config = self.get_config(tenant_id, agent_bot_config)
        return config.system_prompt or DEFAULT_PROMPTS["assistant"]
    
    def clear_cache(self, tenant_id: Optional[int] = None):
        """Limpa cache de configurações."""
        if tenant_id:
            self._cache.pop(tenant_id, None)
        else:
            self._cache.clear()


_tenant_config_service: Optional[TenantConfigService] = None


def get_tenant_config_service() -> TenantConfigService:
    """Retorna instância singleton do serviço."""
    global _tenant_config_service
    if _tenant_config_service is None:
        _tenant_config_service = TenantConfigService()
    return _tenant_config_service