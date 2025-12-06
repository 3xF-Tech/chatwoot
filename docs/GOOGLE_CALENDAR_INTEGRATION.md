# Google Calendar Integration - Setup Guide

## Visão Geral

A integração com Google Calendar permite sincronização bidirecional de eventos entre o CRM e o Google Calendar do usuário. Esta integração possibilita:

- ✅ Sincronização automática de eventos
- ✅ Criação de eventos vinculados a Contatos, Oportunidades, Empresas e Conversas
- ✅ Webhooks para atualizações em tempo real
- ✅ Suporte a múltiplos calendários

## Status Atual

| Componente | Status |
|------------|--------|
| Backend (API) | ✅ Implementado |
| Frontend (UI) | ✅ Implementado |
| Modelos de Dados | ✅ Implementado |
| Sincronização | ✅ Implementado |
| OAuth Flow | ✅ Implementado |
| **Credenciais OAuth** | ❌ **NÃO CONFIGURADO** |

## O Que Falta Configurar

### 1. Criar Projeto no Google Cloud Console

1. Acesse: https://console.cloud.google.com/
2. Crie um novo projeto ou selecione um existente
3. Habilite a **Google Calendar API**:
   - Vá em "APIs & Services" > "Library"
   - Pesquise "Google Calendar API"
   - Clique em "Enable"

### 2. Configurar OAuth Consent Screen

1. Vá em "APIs & Services" > "OAuth consent screen"
2. Selecione "External" (ou "Internal" se for G Suite)
3. Preencha:
   - **App name**: 3xF.Tech CRM
   - **User support email**: seu email
   - **Developer contact**: seu email
4. Em "Scopes", adicione:
   - `https://www.googleapis.com/auth/calendar`
   - `https://www.googleapis.com/auth/calendar.events`
   - `https://www.googleapis.com/auth/userinfo.email`
5. Adicione usuários de teste (enquanto estiver em modo de teste)

### 3. Criar Credenciais OAuth 2.0

1. Vá em "APIs & Services" > "Credentials"
2. Clique em "Create Credentials" > "OAuth client ID"
3. Selecione "Web application"
4. Configure:
   - **Name**: 3xF.Tech CRM Calendar
   - **Authorized JavaScript origins**:
     ```
     http://localhost:3000
     https://seu-dominio.com
     ```
   - **Authorized redirect URIs**:
     ```
     http://localhost:3000/google/calendar/callback
     https://seu-dominio.com/google/calendar/callback
     ```
     
     > **Nota:** Agora usamos uma callback URL fixa! Não é mais necessário adicionar uma URI por conta.
     > O account_id e user_id são passados de forma segura via parâmetro `state`.
5. Copie o **Client ID** e **Client Secret**

### 4. Configurar Variáveis de Ambiente

O Google Calendar agora usa as **mesmas credenciais** do Google OAuth login.

Adicione ao seu arquivo `.env`:

```bash
# Google OAuth Credentials (usado para login E calendar)
GOOGLE_OAUTH_CLIENT_ID=seu-client-id.apps.googleusercontent.com
GOOGLE_OAUTH_CLIENT_SECRET=seu-client-secret
```

> **Nota:** Se você precisar credenciais separadas para o Calendar, pode usar:
> - `GOOGLE_CALENDAR_CLIENT_ID`
> - `GOOGLE_CALENDAR_CLIENT_SECRET`
> Mas isso geralmente não é necessário.

### 5. Reiniciar a Aplicação

Após configurar as variáveis, reinicie o servidor:

```bash
# Para ou Ctrl+C no Rails server e Vite
pkill -f "rails server"

# Reinicie
bin/rails server -b 0.0.0.0
pnpm dev
```

## Fluxo de Autenticação

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Usuário       │     │   3xF.Tech CRM   │     │  Google OAuth   │
│   (Frontend)    │     │    (Backend)     │     │                 │
└────────┬────────┘     └────────┬─────────┘     └────────┬────────┘
         │                       │                        │
         │ 1. Clica "Connect"    │                        │
         │──────────────────────>│                        │
         │                       │                        │
         │ 2. Retorna auth_url   │                        │
         │<──────────────────────│                        │
         │                       │                        │
         │ 3. Redireciona para Google                     │
         │───────────────────────────────────────────────>│
         │                       │                        │
         │ 4. Usuário autoriza   │                        │
         │                       │                        │
         │ 5. Google redireciona com código               │
         │<───────────────────────────────────────────────│
         │                       │                        │
         │ 6. Envia código       │                        │
         │──────────────────────>│                        │
         │                       │                        │
         │                       │ 7. Troca código por tokens
         │                       │───────────────────────>│
         │                       │                        │
         │                       │ 8. Retorna tokens      │
         │                       │<───────────────────────│
         │                       │                        │
         │ 9. Salva tokens       │                        │
         │ 10. Inicia sync       │                        │
         │<──────────────────────│                        │
         │                       │                        │
```

## Estrutura de Arquivos

```
app/
├── controllers/
│   └── api/v1/accounts/
│       ├── calendar_integrations_controller.rb  # OAuth e CRUD
│       └── calendar_events_controller.rb        # Eventos
│
├── models/
│   ├── calendar_integration.rb      # Token OAuth
│   ├── calendar_event.rb            # Eventos
│   ├── calendar_event_attendee.rb   # Participantes
│   └── calendar_event_link.rb       # Links polimórficos
│
├── services/
│   └── calendar/
│       ├── providers/
│       │   └── google_calendar_service.rb  # API do Google
│       └── sync_service.rb                 # Sincronização
│
├── jobs/
│   └── calendar/
│       ├── sync_job.rb               # Sync completo
│       ├── sync_event_job.rb         # Sync individual
│       └── refresh_webhooks_job.rb   # Renovar webhooks
│
└── javascript/dashboard/
    ├── api/
    │   ├── calendarIntegrations.js
    │   └── calendarEvents.js
    │
    ├── store/modules/
    │   ├── calendarIntegrations.js
    │   └── calendarEvents.js
    │
    └── routes/dashboard/
        └── calendar/
            ├── CalendarIndex.vue
            ├── CalendarView.vue
            ├── CalendarSettings.vue
            └── components/
                ├── CalendarGrid.vue
                ├── CalendarHeader.vue
                ├── CalendarSidebar.vue
                ├── EventDialog.vue
                └── EventQuickView.vue
```

## Tabelas do Banco de Dados

### calendar_integrations
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | bigint | PK |
| account_id | bigint | FK para accounts |
| user_id | bigint | FK para users |
| provider | string | 'google', 'outlook', 'calendly' |
| access_token | text | Token OAuth (encriptado) |
| refresh_token | text | Refresh token (encriptado) |
| token_expires_at | datetime | Expiração do token |
| provider_email | string | Email do provedor |
| calendar_id | string | ID do calendário selecionado |
| sync_status | string | 'pending', 'synced', 'error' |

### calendar_events
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | bigint | PK |
| account_id | bigint | FK para accounts |
| user_id | bigint | FK para users |
| title | string | Título do evento |
| starts_at | datetime | Início |
| ends_at | datetime | Fim |
| event_type | string | 'meeting', 'call', 'task', etc |
| status | string | 'confirmed', 'tentative', 'cancelled' |
| external_id | string | ID no Google Calendar |
| sync_status | string | 'local', 'synced', 'pending_sync' |

## Próximos Passos

1. **Configurar credenciais OAuth** (descrito acima)
2. **Testar fluxo de conexão** no ambiente de desenvolvimento
3. **Publicar app OAuth** no Google Cloud Console (para produção)
4. **Configurar webhooks** para sync em tempo real (opcional)

## Troubleshooting

### Erro: "Google Calendar credentials not configured"
- Verifique se as variáveis de ambiente estão configuradas
- Reinicie o servidor Rails

### Erro: "redirect_uri_mismatch"
- Verifique se a URL de callback está correta no Google Cloud Console
- O formato é: `{BASE_URL}/google/calendar/callback`
- Exemplo: `https://chat.3xf.app/google/calendar/callback`

### Erro: "access_denied"
- Usuário não está na lista de usuários de teste (se app não publicado)
- Escopos não foram aprovados

## Contato

Para dúvidas sobre a integração, entre em contato com a equipe de desenvolvimento.
