# frozen_string_literal: true

class Calendar::SyncJob < ApplicationJob
  queue_as :low

  def perform(integration_id, incremental: false)
    integration = CalendarIntegration.find_by(id: integration_id)
    return unless integration

    sync_service = Calendar::SyncService.new(integration)

    if incremental
      sync_service.incremental_sync
    else
      sync_service.full_sync
    end
  rescue StandardError => e
    Rails.logger.error("Calendar sync failed for integration #{integration_id}: #{e.message}")
    integration&.update(sync_status: 'error', sync_error: e.message)
    raise
  end
end
