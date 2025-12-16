"""
Grafo do Agente LangGraph.
Define a estrutura de processamento do agente com tools e LLM.
"""
from dotenv import load_dotenv
load_dotenv()

import os
import sys
from typing import TypedDict, Annotated, List, Optional

from langchain_openai import ChatOpenAI
from langchain_core.messages import BaseMessage, HumanMessage, SystemMessage
from langchain_core.tools import tool
from langgraph.graph import StateGraph, END, START
from langgraph.prebuilt import ToolNode, tools_condition
from langfuse.callback import CallbackHandler
from langgraph.graph.message import add_messages

# Adiciona o diretório pai ao path para imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.config import get_settings

settings = get_settings()


class AgentState(TypedDict):
    """Estado do agente durante execução."""
    messages: Annotated[List[BaseMessage], add_messages]
    tenant_id: str


# --- Ferramentas ---
@tool
def calculadora(a: float, b: float, operacao: str = "soma") -> float:
    """
    Realiza operações matemáticas básicas.
    
    Args:
        a: Primeiro número
        b: Segundo número
        operacao: Tipo de operação (soma, subtracao, multiplicacao, divisao)
    """
    if operacao == "soma":
        return a + b
    elif operacao == "subtracao":
        return a - b
    elif operacao == "multiplicacao":
        return a * b
    elif operacao == "divisao":
        if b == 0:
            return float('inf')
        return a / b
    return a + b


@tool
def buscar_horarios_disponiveis(data: str) -> str:
    """
    Busca horários disponíveis para agendamento em uma data.
    
    Args:
        data: Data no formato DD/MM/YYYY
    """
    # TODO: Integrar com sistema de agendamento real
    return f"Horarios disponiveis para {data}: 09:00, 10:00, 14:00, 15:00, 16:00"


@tool
def verificar_disponibilidade_produto(produto: str) -> str:
    """
    Verifica disponibilidade de um produto.
    
    Args:
        produto: Nome do produto
    """
    # TODO: Integrar com sistema de estoque real
    return f"O produto '{produto}' esta disponivel em estoque."


# Lista de tools disponíveis
AVAILABLE_TOOLS = [calculadora, buscar_horarios_disponiveis, verificar_disponibilidade_produto]


def create_langfuse_handler(tenant_id: str) -> CallbackHandler:
    """Cria handler do Langfuse para tracing."""
    return CallbackHandler(
        public_key=settings.langfuse_public_key,
        secret_key=settings.langfuse_secret_key,
        host=settings.langfuse_host,
        user_id=tenant_id
    )


def create_agent_graph(
    system_prompt: Optional[str] = None,
    model_name: Optional[str] = None,
    temperature: float = 0.7,
    tools: Optional[List] = None
):
    """
    Cria um grafo de agente configurável.
    
    Args:
        system_prompt: Prompt do sistema (personalidade do agente)
        model_name: Nome do modelo OpenAI
        temperature: Temperatura do modelo
        tools: Lista de ferramentas disponíveis
        
    Returns:
        Grafo compilado pronto para execução
    """
    # Configurações
    _model_name = model_name or settings.openai_model
    _tools = tools or AVAILABLE_TOOLS
    _system_prompt = system_prompt or "Voce e um assistente virtual prestativo."
    
    # Modelo
    llm = ChatOpenAI(
        model=_model_name,
        temperature=temperature,
        api_key=settings.openai_api_key
    )
    llm_with_tools = llm.bind_tools(_tools)
    
    def call_model(state: AgentState):
        """Nó que chama o modelo LLM."""
        messages = state["messages"]
        tenant_id = state.get("tenant_id", "anon")
        
        # Adiciona system prompt se não existir
        if not any(isinstance(m, SystemMessage) for m in messages):
            messages = [SystemMessage(content=_system_prompt)] + list(messages)
        
        # Handler do Langfuse
        handler = create_langfuse_handler(tenant_id)
        
        response = llm_with_tools.invoke(messages, config={"callbacks": [handler]})
        return {"messages": [response]}
    
    # Monta o grafo
    workflow = StateGraph(AgentState)
    
    workflow.add_node("agent", call_model)
    workflow.add_node("tools", ToolNode(_tools))
    
    workflow.add_edge(START, "agent")
    workflow.add_conditional_edges("agent", tools_condition)
    workflow.add_edge("tools", "agent")
    
    return workflow.compile()


# Grafo padrão para compatibilidade
app = create_agent_graph()
