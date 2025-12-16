class Enterprise::AiAgents::CreateAgentService
  WEBHOOK_BASE_URL = 'https://webhooks.3xf.app/data'.freeze
  AGENT_CREATION_WEBHOOKS = {
    'atendimento' => '356ce6f2-69ee-4b48-98dc-4d975379d1d5'
  }.freeze

  pattr_initialize [:account!, :plan_id!, :subscription!]

  def perform
    agent_bot = create_agent_bot
    response = call_creation_webhook(agent_bot)
    update_agent_with_workflow(agent_bot, response)
    agent_bot
  rescue StandardError => e
    Rails.logger.error "AI Agent creation failed: #{e.message}"
    raise e
  end

  private

  def create_agent_bot
    plan_config = AiAgentSubscription.plans_config[plan_id]

    account.agent_bots.create!(
      name: plan_config['name'],
      description: plan_config['description'],
      ai_agent_type: plan_id,
      bot_type: :webhook,
      is_active: false,
      bot_config: {
        subscription_id: subscription.id,
        plan_id: plan_id
      }
    )
  end

  def call_creation_webhook(agent_bot)
    webhook_id = AGENT_CREATION_WEBHOOKS[plan_id]
    raise StandardError, "No webhook configured for plan: #{plan_id}" if webhook_id.blank?

    webhook_url = "#{WEBHOOK_BASE_URL}/#{webhook_id}"

    response = HTTParty.post(
      webhook_url,
      headers: { 'Content-Type' => 'application/json' },
      body: creation_payload(agent_bot).to_json,
      timeout: 30
    )

    raise StandardError, "Webhook call failed: #{response.code} - #{response.body}" unless response.success?

    parse_webhook_response(response)
  end

  def creation_payload(agent_bot)
    {
      account: {
        id: account.id,
        name: account.name
      },
      agent: {
        id: agent_bot.id,
        name: agent_bot.name,
        ai_agent_type: agent_bot.ai_agent_type
      },
      subscription: {
        id: subscription.id,
        plan_id: subscription.plan_id,
        stripe_subscription_id: subscription.stripe_subscription_id,
        stripe_customer_id: subscription.stripe_customer_id
      },
      webhook_response_path: "crm_3xfapp_#{account.id}_#{agent_bot.id}"
    }
  end

  def parse_webhook_response(response)
    body = response.parsed_response
    body = body.first if body.is_a?(Array)
    body
  end

  def update_agent_with_workflow(agent_bot, response)
    workflow_data = response['workflow'] || response
    outgoing_url = "#{WEBHOOK_BASE_URL}/crm_3xfapp_#{account.id}_#{agent_bot.id}"

    agent_bot.update!(
      workflow_id: workflow_data['id'],
      workflow_version_id: response['versionId'],
      workflow_active: response['active'] || false,
      outgoing_url: outgoing_url,
      is_active: true
    )

    Rails.logger.info "AI Agent created: agent_id=#{agent_bot.id}, workflow_id=#{workflow_data['id']}, outgoing_url=#{outgoing_url}"
  end
end
