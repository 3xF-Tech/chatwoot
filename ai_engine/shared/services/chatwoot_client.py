"""
Cliente para API do Chatwoot.
Usado para enviar respostas do agente de volta para as conversas.
"""
import logging
import requests
from typing import Optional, Dict, Any
from ..config import get_settings
from ..schemas import ChatwootMessageRequest

logger = logging.getLogger(__name__)


class ChatwootClient:
    """
    Cliente HTTP para API do Chatwoot.
    Envia mensagens de resposta do agente IA.
    """
    
    def __init__(self, base_url: Optional[str] = None, api_token: Optional[str] = None):
        self.settings = get_settings()
        self.base_url = (base_url or self.settings.chatwoot_base_url).rstrip("/")
        self.api_token = api_token or self.settings.chatwoot_api_token
        self.timeout = 30
    
    def _get_headers(self, api_token: Optional[str] = None) -> Dict[str, str]:
        """Retorna headers para requisição."""
        token = api_token or self.api_token
        return {
            "Content-Type": "application/json",
            "api_access_token": token
        }
    
    def send_message(
        self,
        account_id: int,
        conversation_id: int,
        content: str,
        private: bool = False,
        api_token: Optional[str] = None,
        message_type: str = "outgoing",
        content_attributes: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Envia uma mensagem para uma conversa no Chatwoot.
        
        API: POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/messages
        
        Args:
            account_id: ID da conta
            conversation_id: ID da conversa
            content: Texto da mensagem
            private: Se True, envia como nota privada
            api_token: Token de API (usa config se não fornecido)
            message_type: Tipo da mensagem (outgoing por padrão)
            content_attributes: Atributos adicionais
            
        Returns:
            Response JSON do Chatwoot
            
        Raises:
            requests.HTTPError: Se a requisição falhar
        """
        url = f"{self.base_url}/api/v1/accounts/{account_id}/conversations/{conversation_id}/messages"
        
        payload = {
            "content": content,
            "message_type": message_type,
            "private": private
        }
        
        if content_attributes:
            payload["content_attributes"] = content_attributes
        
        logger.info(f"Enviando mensagem para Chatwoot: account={account_id}, conversation={conversation_id}")
        
        try:
            response = requests.post(
                url,
                json=payload,
                headers=self._get_headers(api_token),
                timeout=self.timeout
            )
            response.raise_for_status()
            
            result = response.json()
            logger.info(f"Mensagem enviada com sucesso: message_id={result.get('id')}")
            return result
            
        except requests.HTTPError as e:
            logger.error(f"Erro HTTP ao enviar mensagem: {e.response.status_code} - {e.response.text}")
            raise
        except requests.RequestException as e:
            logger.error(f"Erro de conexão com Chatwoot: {e}")
            raise
    
    def get_conversation(
        self,
        account_id: int,
        conversation_id: int,
        api_token: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Busca informações de uma conversa.
        
        Args:
            account_id: ID da conta
            conversation_id: ID da conversa
            api_token: Token de API
            
        Returns:
            Dados da conversa
        """
        url = f"{self.base_url}/api/v1/accounts/{account_id}/conversations/{conversation_id}"
        
        response = requests.get(
            url,
            headers=self._get_headers(api_token),
            timeout=self.timeout
        )
        response.raise_for_status()
        return response.json()
    
    def get_messages(
        self,
        account_id: int,
        conversation_id: int,
        api_token: Optional[str] = None,
        before: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Busca mensagens de uma conversa (para contexto/memória).
        
        Args:
            account_id: ID da conta
            conversation_id: ID da conversa
            api_token: Token de API
            before: ID da mensagem para paginar
            
        Returns:
            Lista de mensagens
        """
        url = f"{self.base_url}/api/v1/accounts/{account_id}/conversations/{conversation_id}/messages"
        
        params = {}
        if before:
            params["before"] = before
        
        response = requests.get(
            url,
            params=params,
            headers=self._get_headers(api_token),
            timeout=self.timeout
        )
        response.raise_for_status()
        return response.json()
    
    def get_agent_bot(
        self,
        account_id: int,
        agent_bot_id: int,
        api_token: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Busca configuração de um AgentBot.
        
        Args:
            account_id: ID da conta
            agent_bot_id: ID do AgentBot
            api_token: Token de API
            
        Returns:
            Dados do AgentBot
        """
        url = f"{self.base_url}/api/v1/accounts/{account_id}/agent_bots/{agent_bot_id}"
        
        response = requests.get(
            url,
            headers=self._get_headers(api_token),
            timeout=self.timeout
        )
        response.raise_for_status()
        return response.json()


# Singleton
_chatwoot_client: Optional[ChatwootClient] = None


def get_chatwoot_client() -> ChatwootClient:
    """Retorna instância singleton do cliente."""
    global _chatwoot_client
    if _chatwoot_client is None:
        _chatwoot_client = ChatwootClient()
    return _chatwoot_client
