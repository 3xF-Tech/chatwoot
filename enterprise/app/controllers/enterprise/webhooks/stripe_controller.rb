class Enterprise::Webhooks::StripeController < ActionController::API
  def process_payload
    # Get the event payload and signature
    payload = request.body.read
    sig_header = request.headers['Stripe-Signature']

    # Attempt to verify the signature. If successful, we'll handle the event
    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, ENV.fetch('STRIPE_WEBHOOK_SECRET', nil))

      # Route to appropriate handler based on event metadata
      if ai_agent_event?(event)
        ::Enterprise::Billing::HandleAiAgentStripeEventService.new.perform(event: event)
      else
        ::Enterprise::Billing::HandleStripeEventService.new.perform(event: event)
      end
    # If we fail to verify the signature, then something was wrong with the request
    rescue JSON::ParserError, Stripe::SignatureVerificationError
      # Invalid payload
      head :bad_request
      return
    end

    # We've successfully processed the event without blowing up
    head :ok
  end

  private

  def ai_agent_event?(event)
    object = event.data.object
    metadata = object.respond_to?(:metadata) ? object.metadata : nil
    metadata&.type == 'ai_agent_subscription'
  end
end
