class Enterprise::RecordAiAgentUsageJob < ApplicationJob
  queue_as :low

  def perform(subscription_id)
    subscription = AiAgentSubscription.find_by(id: subscription_id)
    return if subscription.blank?
    return unless subscription.active?

    if subscription.stripe_customer_id.present?
      Enterprise::Billing::StripeMeterEventService.new(subscription: subscription).perform
    else
      subscription.record_message!
    end
  end
end
