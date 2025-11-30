# frozen_string_literal: true

class Calendar::RefreshWebhooksJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    # Google Calendar webhooks expire, so we need to refresh them
    CalendarIntegration.where(provider: 'google').find_each do |integration|
      next unless integration.webhook_expiration&.< 1.day.from_now

      service = Calendar::Providers::GoogleCalendarService.new
      callback_url = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/webhooks/calendar/google"
      service.setup_webhook(integration, callback_url)
    rescue StandardError => e
      Rails.logger.error("Failed to refresh webhook for integration #{integration.id}: #{e.message}")
    end
  end
end
