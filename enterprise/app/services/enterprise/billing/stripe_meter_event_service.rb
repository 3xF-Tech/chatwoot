class Enterprise::Billing::StripeMeterEventService
  STRIPE_METER_EVENTS_URL = 'https://api.stripe.com/v1/billing/meter_events'.freeze
  METER_EVENT_NAME = 'mensagens_do_agente_ia'.freeze

  pattr_initialize [:subscription!, :value]

  def perform
    return unless valid_subscription?

    send_meter_event
    subscription.record_message!
  rescue StandardError => e
    Rails.logger.error "Stripe meter event failed: #{e.message}"
    raise e
  end

  private

  def valid_subscription?
    subscription.present? &&
      subscription.active? &&
      subscription.stripe_customer_id.present? &&
      stripe_api_key.present?
  end

  def send_meter_event
    response = HTTParty.post(
      STRIPE_METER_EVENTS_URL,
      basic_auth: { username: stripe_api_key, password: '' },
      body: meter_event_params
    )

    unless response.success?
      error_message = response.parsed_response['error']&.dig('message') || response.body
      raise StandardError, "Stripe API error: #{error_message}"
    end

    Rails.logger.info "Stripe meter event sent: subscription=#{subscription.id}, customer=#{subscription.stripe_customer_id}, value=#{meter_value}"
    response
  end

  def meter_event_params
    {
      :event_name => METER_EVENT_NAME,
      'payload[stripe_customer_id]' => subscription.stripe_customer_id,
      'payload[value]' => meter_value.to_s,
      :identifier => event_identifier,
      :timestamp => Time.current.to_i
    }
  end

  def stripe_api_key
    ENV.fetch('STRIPE_SECRET_KEY', nil)
  end

  def meter_value
    @value || 1
  end

  def event_identifier
    "#{subscription.id}-#{subscription.account_id}-#{Time.current.to_i}-#{SecureRandom.hex(4)}"
  end
end
