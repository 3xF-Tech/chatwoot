# Chatwoot AI Engine v0.2.0

Motor de Agentes de IA para o Chatwoot CRM, com arquitetura assincrona baseada em fila para alta escalabilidade.

## Arquitetura

Chatwoot (webhook) --> API Gateway --> RabbitMQ --> Worker --> Chatwoot (API)

### Componentes

1. **API Gateway** (FastAPI): Recebe webhooks, filtra, valida idempotencia e enfileira
2. **RabbitMQ**: Message broker com DLQ para retry/falhas
3. **Worker**: Consome fila, executa LangGraph/LLM e envia resposta ao Chatwoot
4. **Redis**: Cache para idempotencia e checkpoints
5. **Langfuse**: Observabilidade e tracing

## Quick Start (Dev)

### 1. Subir infraestrutura
docker-compose -f docker-compose.ai.yml up -d

### 2. Instalar dependencias
cd ai_engine && poetry install

### 3. Configurar ambiente
cp .env.example .env

### 4. Rodar Gateway
poetry run uvicorn api_gateway.main:app --reload --port 8000

### 5. Rodar Worker
poetry run python worker/main.py

## Funcionalidades

- Anti-loop (ignora mensagens do bot)
- Idempotencia via Redis
- Retry com backoff exponencial + DLQ
- Multi-tenant (prompts por AgentBot)
- Observabilidade via Langfuse
- Resposta automatica no Chatwoot

## Producao

Ver docker-compose.ai.yml para stack completa.
Usar profiles=full para incluir gateway e worker.
