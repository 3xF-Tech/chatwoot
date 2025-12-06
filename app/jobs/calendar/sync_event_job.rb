# frozen_string_literal: true

class Calendar::SyncEventJob < ApplicationJob
  queue_as :default

  def perform(event_id, action)
    event = CalendarEvent.find_by(id: event_id)
    return unless event&.calendar_integration

    process_event_action(event, action)
  rescue StandardError => e
    Rails.logger.error("Calendar event sync failed for event #{event_id}: #{e.message}")
    raise
  end

  private

  def process_event_action(event, action)
    integration = event.calendar_integration
    provider_service = get_provider_service(integration.provider)

    case action
    when 'upsert'
      sync_event_to_provider(event, integration, provider_service)
    when 'delete'
      provider_service.delete_event(integration, event.external_id) if event.external_id.present?
    end
  end

  def sync_event_to_provider(event, integration, provider_service)
    if event.external_id.present?
      provider_service.update_event(integration, event)
    else
      external_id = provider_service.create_event(integration, event)
      event.update(external_id: external_id) if external_id
    end
  end

  def get_provider_service(provider)
    case provider
    when 'google'
      Calendar::Providers::GoogleCalendarService.new
    when 'outlook'
      Calendar::Providers::OutlookCalendarService.new
    else
      raise "Unsupported provider: #{provider}"
    end
  end
end
