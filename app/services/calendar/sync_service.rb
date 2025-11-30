# frozen_string_literal: true

class Calendar::SyncService
  def initialize(calendar_integration)
    @integration = calendar_integration
    @provider_service = provider_service_for(@integration.provider)
  end

  def sync!
    return unless @integration.connected?

    @integration.mark_syncing!

    ActiveRecord::Base.transaction do
      pull_remote_events
      push_local_events
    end

    @integration.mark_synced!
  rescue StandardError => e
    @integration.mark_error!
    Rails.logger.error("Calendar sync failed for integration #{@integration.id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end

  private

  def pull_remote_events
    remote_events = @provider_service.fetch_events(
      @integration,
      time_min: 1.month.ago,
      time_max: 3.months.from_now
    )

    remote_events.each do |remote_event|
      sync_remote_event(remote_event)
    end

    # Mark events deleted remotely
    mark_deleted_events(remote_events.pluck(:id))
  end

  def sync_remote_event(remote_event)
    local_event = CalendarEvent.find_by(
      external_id: remote_event[:id],
      calendar_integration: @integration
    )

    if local_event
      update_local_event(local_event, remote_event)
    else
      create_local_event(remote_event)
    end
  end

  def create_local_event(remote_event)
    event = @integration.calendar_events.create!(
      account: @integration.account,
      user: @integration.user,
      external_id: remote_event[:id],
      title: remote_event[:title],
      description: remote_event[:description],
      starts_at: remote_event[:starts_at],
      ends_at: remote_event[:ends_at],
      all_day: remote_event[:all_day],
      location: remote_event[:location],
      status: remote_event[:status],
      meeting_url: remote_event[:meeting_url],
      metadata: remote_event[:metadata] || {},
      sync_status: 'synced',
      synced_at: Time.current
    )

    sync_attendees(event, remote_event[:attendees] || [])
    event
  end

  def update_local_event(local_event, remote_event)
    # Skip if local changes are pending
    return if local_event.sync_status == 'pending_sync'

    local_event.update!(
      title: remote_event[:title],
      description: remote_event[:description],
      starts_at: remote_event[:starts_at],
      ends_at: remote_event[:ends_at],
      all_day: remote_event[:all_day],
      location: remote_event[:location],
      status: remote_event[:status],
      meeting_url: remote_event[:meeting_url],
      metadata: remote_event[:metadata] || {},
      sync_status: 'synced',
      synced_at: Time.current
    )

    sync_attendees(local_event, remote_event[:attendees] || [])
  end

  def sync_attendees(event, remote_attendees)
    existing_emails = event.attendees.pluck(:email)
    remote_emails = remote_attendees.pluck(:email)

    # Remove attendees not in remote
    event.attendees.where.not(email: remote_emails).destroy_all

    # Add/update attendees
    remote_attendees.each do |attendee_data|
      attendee = event.attendees.find_or_initialize_by(email: attendee_data[:email])
      attendee.assign_attributes(
        name: attendee_data[:name],
        response_status: attendee_data[:response_status] || 'pending',
        is_organizer: attendee_data[:is_organizer] || false,
        is_optional: attendee_data[:is_optional] || false
      )

      # Try to link to existing contact
      if attendee.contact_id.blank?
        contact = Contact.find_by(account_id: @integration.account_id, email: attendee_data[:email])
        attendee.contact = contact if contact
      end

      attendee.save!
    end
  end

  def mark_deleted_events(remote_event_ids)
    @integration.calendar_events
                .where.not(external_id: remote_event_ids)
                .where(sync_status: 'synced')
                .update_all(status: 'cancelled')
  end

  def push_local_events
    local_only_events = @integration.account.calendar_events
                                    .where(user: @integration.user)
                                    .where(sync_status: 'local')
                                    .or(
                                      @integration.account.calendar_events
                                        .where(user: @integration.user)
                                        .where(sync_status: 'pending_sync')
                                    )

    local_only_events.find_each do |event|
      push_event_to_remote(event)
    end
  end

  def push_event_to_remote(event)
    if event.external_id.present?
      @provider_service.update_event(@integration, event)
    else
      external_id = @provider_service.create_event(@integration, event)
      event.update!(
        external_id: external_id,
        calendar_integration: @integration
      )
    end

    event.update!(
      sync_status: 'synced',
      synced_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.error("Failed to push event #{event.id}: #{e.message}")
  end

  def provider_service_for(provider)
    case provider
    when 'google'
      Calendar::Providers::GoogleCalendarService.new
    when 'outlook'
      Calendar::Providers::OutlookCalendarService.new
    when 'calendly'
      Calendar::Providers::CalendlyService.new
    else
      raise "Unknown calendar provider: #{provider}"
    end
  end
end
