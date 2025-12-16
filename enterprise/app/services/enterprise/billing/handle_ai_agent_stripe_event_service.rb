class Enterprise::Billing::HandleAiAgentStripeEventService
  def perform(event:)
    @event = event

    case @event.type
    when 'checkout.session.completed'
      process_checkout_completed
    when 'customer.subscription.updated'
      process_subscription_updated
    when 'customer.subscription.deleted'
      process_subscription_deleted
    when 'invoice.payment_succeeded'
      process_payment_succeeded
    when 'invoice.payment_failed'
      process_payment_failed
    end
  end

  private

  def process_checkout_completed
    session = @event.data.object
    return unless ai_agent_subscription?(session)

    account = Account.find(session.metadata.account_id)
    plan_id = session.metadata.plan_id

    # Get the subscription from Stripe
    stripe_subscription = Stripe::Subscription.retrieve(session.subscription)

    # Find or create the subscription record
    subscription = account.ai_agent_subscriptions.find_or_initialize_by(plan_id: plan_id)
    subscription.update!(
      stripe_subscription_id: stripe_subscription.id,
      stripe_customer_id: stripe_subscription.customer,
      stripe_price_id: stripe_subscription.items.data.first.price.id,
      status: 'active',
      current_period_start: Time.zone.at(stripe_subscription.current_period_start),
      current_period_end: Time.zone.at(stripe_subscription.current_period_end),
      messages_used_this_month: 0
    )

    Rails.logger.info "AI Agent subscription activated for account #{account.id}, plan: #{plan_id}"

    # Create the AI Agent via webhook
    Enterprise::CreateAiAgentJob.perform_later(account.id, plan_id, subscription.id)
  end

  def process_subscription_updated
    stripe_subscription = @event.data.object
    return unless ai_agent_subscription?(stripe_subscription)

    subscription = AiAgentSubscription.find_by(stripe_subscription_id: stripe_subscription.id)
    return if subscription.blank?

    subscription.update!(
      status: map_stripe_status(stripe_subscription.status),
      current_period_start: Time.zone.at(stripe_subscription.current_period_start),
      current_period_end: Time.zone.at(stripe_subscription.current_period_end)
    )

    Rails.logger.info "AI Agent subscription updated: #{subscription.id}, status: #{subscription.status}"
  end

  def process_subscription_deleted
    stripe_subscription = @event.data.object
    return unless ai_agent_subscription?(stripe_subscription)

    subscription = AiAgentSubscription.find_by(stripe_subscription_id: stripe_subscription.id)
    return if subscription.blank?

    subscription.update!(status: 'canceled')

    Rails.logger.info "AI Agent subscription canceled: #{subscription.id}"
  end

  def process_payment_succeeded
    invoice = @event.data.object
    subscription_id = invoice.subscription
    return if subscription_id.blank?

    subscription = AiAgentSubscription.find_by(stripe_subscription_id: subscription_id)
    return if subscription.blank?

    # Reset monthly usage on successful payment (new billing cycle)
    subscription.reset_monthly_usage!

    Rails.logger.info "AI Agent subscription payment succeeded, usage reset: #{subscription.id}"
  end

  def process_payment_failed
    invoice = @event.data.object
    subscription_id = invoice.subscription
    return if subscription_id.blank?

    subscription = AiAgentSubscription.find_by(stripe_subscription_id: subscription_id)
    return if subscription.blank?

    subscription.update!(status: 'past_due')

    Rails.logger.info "AI Agent subscription payment failed: #{subscription.id}"
  end

  def ai_agent_subscription?(object)
    object.metadata&.type == 'ai_agent_subscription'
  end

  def map_stripe_status(stripe_status)
    case stripe_status
    when 'active', 'trialing'
      'active'
    when 'past_due'
      'past_due'
    when 'canceled', 'unpaid'
      stripe_status
    else
      'active'
    end
  end
end
