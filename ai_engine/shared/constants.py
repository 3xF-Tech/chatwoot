"""
Constantes usadas em todo o AI Engine.
"""

# Tipos de sender que NÃO devem acionar o agente (anti-loop)
IGNORED_SENDER_TYPES = ["AgentBot", "agent_bot"]

# Eventos do Chatwoot que processamos
ALLOWED_EVENTS = ["message_created"]

# Message types do Chatwoot
MESSAGE_TYPE_INCOMING = 0
MESSAGE_TYPE_OUTGOING = 1
MESSAGE_TYPE_ACTIVITY = 2
MESSAGE_TYPE_TEMPLATE = 3

# Response modes do AgentBot
RESPONSE_MODE_AUTO = "auto_respond"
RESPONSE_MODE_ASSIST = "assist_agent"
RESPONSE_MODE_MANUAL = "manual_trigger"

# Headers esperados do Chatwoot
CHATWOOT_WEBHOOK_SIGNATURE_HEADER = "X-Chatwoot-Signature"

# Limites
MAX_MESSAGE_LENGTH = 10000
MAX_CONTEXT_PROMPT_LENGTH = 10000

# Default system prompts por tipo de agente
DEFAULT_PROMPTS = {
    "atendimento": """Você é um assistente de atendimento ao cliente profissional e prestativo.
Responda de forma clara, educada e objetiva.
Sempre tente resolver a dúvida do cliente ou direcioná-lo corretamente.""",

    "agendamento": """Você é um assistente de agendamento profissional.
Ajude o cliente a marcar, remarcar ou cancelar compromissos.
Sempre confirme data, horário e detalhes antes de finalizar.""",

    "sdr": """Você é um SDR (Sales Development Representative) virtual.
Seu objetivo é qualificar leads e agendar reuniões com o time de vendas.
Seja consultivo, faça perguntas relevantes sobre as necessidades do cliente.""",

    "assistant": """Você é um assistente virtual inteligente.
Ajude o usuário da melhor forma possível."""
}

# Códigos de erro
ERROR_CODES = {
    "DUPLICATE_MESSAGE": "E001",
    "INVALID_PAYLOAD": "E002",
    "LLM_ERROR": "E003",
    "CHATWOOT_API_ERROR": "E004",
    "TIMEOUT": "E005",
    "MAX_RETRIES_EXCEEDED": "E006",
}
