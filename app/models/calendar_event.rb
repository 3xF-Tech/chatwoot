# frozen_string_literal: true

# == Schema Information
#
# Table name: calendar_events
#
#  id                      :bigint           not null, primary key
#  all_day                 :boolean          default(FALSE)
#  description             :text
#  ends_at                 :datetime         not null
#  event_type              :string           default("meeting")
#  location                :string
#  meeting_url             :string
#  metadata                :jsonb
#  recurrence_rule         :jsonb
#  reminders               :jsonb
#  starts_at               :datetime         not null
#  status                  :string           default("confirmed")
#  sync_status             :string           default("local")
#  synced_at               :datetime
#  title                   :string           not null
#  visibility              :string           default("default")
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :bigint           not null
#  calendar_integration_id :bigint
#  external_id             :string
#  recurrence_id           :string
#  user_id                 :bigint           not null
#
# Indexes
#
#  idx_events_external_unique                         (external_id,calendar_integration_id) UNIQUE
#  index_calendar_events_on_account_id                (account_id)
#  index_calendar_events_on_account_id_and_starts_at  (account_id,starts_at)
#  index_calendar_events_on_calendar_integration_id   (calendar_integration_id)
#  index_calendar_events_on_user_id                   (user_id)
#  index_calendar_events_on_user_id_and_starts_at     (user_id,starts_at)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (calendar_integration_id => calendar_integrations.id)
#  fk_rails_...  (user_id => users.id)
#
class CalendarEvent < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :calendar_integration, optional: true

  has_many :attendees, class_name: 'CalendarEventAttendee', dependent: :destroy
  has_many :event_links, class_name: 'CalendarEventLink', dependent: :destroy

  # Polymorphic associations through links
  has_many :linked_opportunities, through: :event_links, source: :linkable, source_type: 'Opportunity'
  has_many :linked_contacts, through: :event_links, source: :linkable, source_type: 'Contact'
  has_many :linked_companies, through: :event_links, source: :linkable, source_type: 'Company'
  has_many :linked_conversations, through: :event_links, source: :linkable, source_type: 'Conversation'

  EVENT_TYPES = %w[meeting call task reminder follow_up other].freeze
  STATUSES = %w[confirmed tentative cancelled].freeze
  SYNC_STATUSES = %w[local synced pending_sync conflict].freeze
  VISIBILITIES = %w[default public private confidential].freeze

  # Aliases for API compatibility
  alias_attribute :start_time, :starts_at
  alias_attribute :end_time, :ends_at
  alias_attribute :video_conference_link, :meeting_url

  # Virtual attributes for frontend compatibility
  attr_accessor :color, :reminder_minutes

  validates :title, presence: true, length: { maximum: 255 }
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validates :event_type, inclusion: { in: EVENT_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :sync_status, inclusion: { in: SYNC_STATUSES }
  validates :visibility, inclusion: { in: VISIBILITIES }
  validate :ends_at_after_starts_at

  before_save :set_all_day_times, if: :all_day?

  scope :upcoming, -> { where('starts_at >= ?', Time.current).order(starts_at: :asc) }
  scope :past, -> { where('ends_at < ?', Time.current).order(starts_at: :desc) }
  scope :today, -> { where(starts_at: Time.current.all_day) }
  scope :this_week, -> { where(starts_at: Time.current.all_week) }
  scope :this_month, -> { where(starts_at: Time.current.all_month) }
  scope :in_range, ->(start_date, end_date) { where(starts_at: start_date..end_date) }
  scope :by_type, ->(event_type) { where(event_type: event_type) }
  scope :confirmed, -> { where(status: 'confirmed') }
  scope :not_cancelled, -> { where.not(status: 'cancelled') }
  scope :needs_sync, -> { where(sync_status: %w[local pending_sync]) }

  def duration_minutes
    ((ends_at - starts_at) / 60).to_i
  end

  def duration_hours
    duration_minutes / 60.0
  end

  def cancelled?
    status == 'cancelled'
  end

  def synced?
    sync_status == 'synced' && external_id.present?
  end

  def link_to!(linkable)
    event_links.find_or_create_by!(linkable: linkable)
  end

  def unlink_from!(linkable)
    event_links.find_by(linkable: linkable)&.destroy
  end

  def add_attendee!(email:, name: nil, contact: nil, user: nil)
    attendees.find_or_create_by!(email: email) do |attendee|
      attendee.name = name
      attendee.contact = contact
      attendee.user = user
    end
  end

  private

  def ends_at_after_starts_at
    return unless starts_at && ends_at

    errors.add(:ends_at, 'must be after start time') if ends_at <= starts_at
  end

  def set_all_day_times
    self.starts_at = starts_at.beginning_of_day
    self.ends_at = ends_at.end_of_day
  end
end
