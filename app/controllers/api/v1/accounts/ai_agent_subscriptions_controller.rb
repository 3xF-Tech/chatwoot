class Api::V1::Accounts::AiAgentSubscriptionsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization!
  before_action :set_subscription, only: [:show, :cancel]

  def index
    @subscriptions = Current.account.ai_agent_subscriptions
    render json: {
      subscriptions: @subscriptions.map { |sub| subscription_json(sub) },
      plans: AiAgentSubscription.plans_config
    }
  end

  def show
    render json: subscription_json(@subscription)
  end

  def create
    plan_id = params[:plan_id]
    plan_config = AiAgentSubscription.plans_config[plan_id]

    return render_error('Invalid plan') if plan_config.blank?

    # Check if already has this plan
    existing = Current.account.ai_agent_subscriptions.find_by(plan_id: plan_id)
    if existing&.active?
      return render json: { error: 'You already have an active subscription for this plan' }, status: :unprocessable_entity
    end

    # Start trial or create checkout session
    if params[:start_trial]
      subscription = create_trial_subscription(plan_id, plan_config)
      render json: subscription_json(subscription), status: :created
    else
      checkout_url = create_stripe_checkout(plan_id, plan_config)
      render json: { checkout_url: checkout_url }
    end
  end

  def checkout
    plan_id = params[:id]
    plan_config = AiAgentSubscription.plans_config[plan_id]

    return render_error('Invalid plan') if plan_config.blank?
    return render_error('Stripe Price ID not configured') if plan_config['stripe_price_id'].blank?

    checkout_url = create_stripe_checkout(plan_id, plan_config)
    render json: { checkout_url: checkout_url }
  end

  def cancel
    return render_error('Subscription not found') unless @subscription

    if @subscription.stripe_subscription_id.present?
      Stripe::Subscription.cancel(@subscription.stripe_subscription_id)
    end

    @subscription.update!(status: 'canceled')
    render json: subscription_json(@subscription)
  end

  def plans
    render json: {
      plans: AiAgentSubscription.plans_config,
      current_subscriptions: Current.account.ai_agent_subscriptions.active.pluck(:plan_id)
    }
  end

  def usage
    subscriptions = Current.account.ai_agent_subscriptions.active
    render json: {
      subscriptions: subscriptions.map do |sub|
        {
          plan_id: sub.plan_id,
          plan_name: sub.plan_name,
          status: sub.status,
          messages_used: sub.trial? ? (50 - sub.trial_messages_remaining) : sub.messages_used_this_month,
          messages_limit: sub.trial? ? 50 : sub.monthly_message_limit,
          messages_remaining: sub.messages_remaining,
          usage_percentage: sub.usage_percentage
        }
      end
    }
  end

  private

  def set_subscription
    @subscription = Current.account.ai_agent_subscriptions.find(params[:id])
  end

  def create_trial_subscription(plan_id, plan_config)
    Current.account.ai_agent_subscriptions.create!(
      plan_id: plan_id,
      status: 'trial',
      trial_messages_remaining: plan_config['trial_messages'] || 50,
      monthly_message_limit: plan_config['monthly_message_limit'] || 1000,
      trial_ends_at: 30.days.from_now
    )
  end

  def create_stripe_checkout(plan_id, plan_config)
    # Get or create Stripe customer
    customer_id = get_or_create_stripe_customer

    session = Stripe::Checkout::Session.create({
      customer: customer_id,
      payment_method_types: ['card'],
      line_items: [{
        price: plan_config['stripe_price_id'],
        quantity: 1
      }],
      mode: 'subscription',
      success_url: success_url(plan_id),
      cancel_url: cancel_url,
      metadata: {
        account_id: Current.account.id,
        plan_id: plan_id,
        type: 'ai_agent_subscription'
      },
      subscription_data: {
        metadata: {
          account_id: Current.account.id,
          plan_id: plan_id,
          type: 'ai_agent_subscription'
        }
      }
    })

    session.url
  end

  def get_or_create_stripe_customer
    customer_id = Current.account.custom_attributes['stripe_customer_id']
    return customer_id if customer_id.present?

    customer = Stripe::Customer.create({
      name: Current.account.name,
      email: Current.account.administrators.first&.email,
      metadata: { account_id: Current.account.id }
    })

    Current.account.update!(
      custom_attributes: Current.account.custom_attributes.merge('stripe_customer_id' => customer.id)
    )

    customer.id
  end

  def success_url(plan_id)
    "#{ENV.fetch('FRONTEND_URL', '')}/app/accounts/#{Current.account.id}/ai-agents/my-agents?checkout=success&plan=#{plan_id}"
  end

  def cancel_url
    "#{ENV.fetch('FRONTEND_URL', '')}/app/accounts/#{Current.account.id}/ai-agents/marketplace?checkout=canceled"
  end

  def subscription_json(subscription)
    {
      id: subscription.id,
      plan_id: subscription.plan_id,
      plan_name: subscription.plan_name,
      status: subscription.status,
      stripe_subscription_id: subscription.stripe_subscription_id,
      monthly_message_limit: subscription.monthly_message_limit,
      trial_messages_remaining: subscription.trial_messages_remaining,
      messages_used_this_month: subscription.messages_used_this_month,
      messages_remaining: subscription.messages_remaining,
      usage_percentage: subscription.usage_percentage,
      current_period_start: subscription.current_period_start,
      current_period_end: subscription.current_period_end,
      trial_ends_at: subscription.trial_ends_at,
      active: subscription.active?,
      trial: subscription.trial?,
      created_at: subscription.created_at,
      updated_at: subscription.updated_at
    }
  end

  def render_error(message)
    render json: { error: message }, status: :unprocessable_entity
  end

  def check_admin_authorization!
    raise Pundit::NotAuthorizedError unless Current.account_user&.administrator?
  end
end
