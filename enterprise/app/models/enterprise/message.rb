module Enterprise::Message
  def self.prepended(base)
    base.class_eval do
      after_create_commit :record_ai_agent_usage, if: :ai_agent_message?
    end
  end

  private

  def ai_agent_message?
    return false unless outgoing?
    return false if private?

    sender_type == 'AgentBot' && sender.present?
  end

  def record_ai_agent_usage
    return unless sender.is_a?(AgentBot)

    agent_bot = sender
    subscription = find_ai_agent_subscription(agent_bot)
    return if subscription.blank?

    Enterprise::RecordAiAgentUsageJob.perform_later(subscription.id)
  end

  def find_ai_agent_subscription(agent_bot)
    plan_id = agent_bot.ai_agent_type
    return nil if plan_id.blank?

    account.ai_agent_subscriptions.active.find_by(plan_id: plan_id)
  end
end
