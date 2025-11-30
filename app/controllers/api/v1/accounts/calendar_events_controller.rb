# frozen_string_literal: true

class Api::V1::Accounts::CalendarEventsController < Api::V1::Accounts::BaseController
  before_action :fetch_event, only: %i[show update destroy]
  before_action :set_date_range, only: [:index]

  def index
    @events = Current.account.calendar_events
                     .includes(:attendees, :event_links, :calendar_integration)
                     .where(starts_at: @start_time..@end_time)
                     .or(Current.account.calendar_events.where(ends_at: @start_time..@end_time))

    @events = @events.where(user_id: Current.user.id) unless params[:all_users] == 'true'
    @events = filter_events(@events)
    @events = @events.order(:starts_at)
  end

  def show; end

  def create
    @event = Current.account.calendar_events.new(event_params)
    @event.user = Current.user
    process_reminders(@event)
    @event.save!

    # Create attendees
    create_attendees(@event)

    # Create links
    create_links(@event)

    # Sync to external calendar if integration exists
    sync_to_provider(@event)

    render :show, status: :created
  end

  def update
    @event.update!(event_params)
    process_reminders(@event)

    # Update attendees
    update_attendees(@event)

    # Update links
    update_links(@event)

    # Sync to external calendar
    sync_to_provider(@event)

    render :show
  end

  def destroy
    # Delete from external calendar
    delete_from_provider(@event)

    @event.destroy!
    head :ok
  end

  def upcoming
    @events = Current.account.calendar_events
                     .includes(:attendees, :event_links)
                     .where(user_id: Current.user.id)
                     .where('starts_at >= ?', Time.current)
                     .order(:starts_at)
                     .limit(params[:limit] || 10)

    render :index
  end

  def by_link
    linkable_type = params[:linkable_type]&.classify
    linkable_id = params[:linkable_id]

    @events = Current.account.calendar_events
                     .joins(:event_links)
                     .where(calendar_event_links: { linkable_type: linkable_type, linkable_id: linkable_id })
                     .includes(:attendees, :event_links)
                     .order(:starts_at)

    render :index
  end

  private

  def fetch_event
    @event = Current.account.calendar_events.find(params[:id])
  end

  def set_date_range
    @start_time = params[:start_time]&.to_datetime || Time.current.beginning_of_month
    @end_time = params[:end_time]&.to_datetime || Time.current.end_of_month
  end

  def filter_events(events)
    events = events.where(event_type: params[:event_type]) if params[:event_type].present?
    events = events.where(status: params[:status]) if params[:status].present?
    events = events.where(calendar_integration_id: params[:integration_id]) if params[:integration_id].present?
    events
  end

  # Field mapping from frontend names to database columns
  FIELD_MAPPING = {
    title: :title,
    description: :description,
    start_time: :starts_at,
    end_time: :ends_at,
    all_day: :all_day,
    location: :location,
    video_conference_link: :meeting_url,
    event_type: :event_type,
    status: :status,
    visibility: :visibility,
    calendar_integration_id: :calendar_integration_id,
    recurrence_rule: :recurrence_rule
  }.freeze

  def event_params
    permitted = params.require(:calendar_event).permit(
      :title, :description, :start_time, :end_time, :all_day, :location,
      :video_conference_link, :event_type, :status, :visibility,
      :calendar_integration_id, recurrence_rule: {}, metadata: {}
    )

    build_mapped_params(permitted).merge(build_metadata(permitted))
  end

  def build_mapped_params(permitted)
    FIELD_MAPPING.each_with_object({}) do |(frontend_key, db_key), result|
      result[db_key] = permitted[frontend_key] if permitted.key?(frontend_key)
    end
  end

  def build_metadata(permitted)
    metadata = permitted[:metadata] || {}
    color = params.dig(:calendar_event, :color)
    metadata[:color] = color if color.present?
    { metadata: metadata }
  end

  def process_reminders(event)
    reminder_minutes = params.dig(:calendar_event, :reminder_minutes)
    return if reminder_minutes.blank?

    event.reminders = [{ minutes: reminder_minutes.to_i, method: 'popup' }]
  end

  def create_attendees(event)
    return if params[:attendees].blank?

    params[:attendees].each do |attendee_params|
      event.attendees.create!(
        contact_id: attendee_params[:contact_id],
        user_id: attendee_params[:user_id],
        email: attendee_params[:email],
        response_status: attendee_params[:response_status] || 'needs_action',
        required: attendee_params[:required] || true
      )
    end
  end

  def update_attendees(event)
    return if params[:attendees].blank?

    event.attendees.destroy_all
    create_attendees(event)
  end

  def create_links(event)
    return if params[:links].blank?

    params[:links].each do |link_params|
      event.links.create!(
        linkable_type: link_params[:linkable_type],
        linkable_id: link_params[:linkable_id]
      )
    end
  end

  def update_links(event)
    return if params[:links].blank?

    event.links.destroy_all
    create_links(event)
  end

  def sync_to_provider(event)
    return if event.calendar_integration.blank?

    Calendar::SyncEventJob.perform_later(event.id, 'upsert')
  end

  def delete_from_provider(event)
    return unless event.calendar_integration.present? && event.external_id.present?

    Calendar::SyncEventJob.perform_later(event.id, 'delete')
  end
end
