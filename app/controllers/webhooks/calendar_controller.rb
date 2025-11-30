# frozen_string_literal: true

class Webhooks::CalendarController < ActionController::API
  skip_before_action :verify_authenticity_token, raise: false

  def google
    # Google Calendar sends X-Goog-Resource-State header
    resource_state = request.headers['X-Goog-Resource-State']
    channel_id = request.headers['X-Goog-Channel-ID']
    request.headers['X-Goog-Resource-ID']

    Rails.logger.info("Google Calendar webhook: state=#{resource_state}, channel=#{channel_id}")

    # Handle sync notification
    if resource_state == 'sync'
      head :ok
      return
    end

    # Find integration by channel_id
    integration = CalendarIntegration.find_by(webhook_channel_id: channel_id)

    unless integration
      Rails.logger.warn("No integration found for channel: #{channel_id}")
      head :not_found
      return
    end

    # Trigger sync for this integration
    Calendar::SyncJob.perform_later(integration.id, incremental: true)

    head :ok
  end

  def outlook
    # Handle Outlook validation request
    if params[:validationToken].present?
      render plain: params[:validationToken], content_type: 'text/plain'
      return
    end

    # Handle notifications
    notifications = params[:value] || []
    notifications.each do |notification|
      subscription_id = notification[:subscriptionId]
      integration = CalendarIntegration.find_by(webhook_channel_id: subscription_id, provider: 'outlook')

      next unless integration

      Calendar::SyncJob.perform_later(integration.id, incremental: true)
    end

    head :accepted
  end
end
