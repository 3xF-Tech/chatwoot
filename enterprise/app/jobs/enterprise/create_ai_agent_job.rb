class Enterprise::CreateAiAgentJob < ApplicationJob
  queue_as :default

  def perform(account_id, plan_id, subscription_id)
    account = Account.find(account_id)
    subscription = AiAgentSubscription.find(subscription_id)

    Enterprise::AiAgents::CreateAgentService.new(
      account: account,
      plan_id: plan_id,
      subscription: subscription
    ).perform
  rescue StandardError => e
    Rails.logger.error "CreateAiAgentJob failed: #{e.message}"
    raise e
  end
end
