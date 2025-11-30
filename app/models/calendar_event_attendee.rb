# frozen_string_literal: true

# == Schema Information
#
# Table name: calendar_event_attendees
#
#  id                :bigint           not null, primary key
#  email             :string
#  is_optional       :boolean          default(FALSE)
#  is_organizer      :boolean          default(FALSE)
#  name              :string
#  response_status   :string           default("pending")
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  calendar_event_id :bigint           not null
#  contact_id        :bigint
#  user_id           :bigint
#
# Indexes
#
#  index_calendar_event_attendees_on_calendar_event_id  (calendar_event_id)
#  index_calendar_event_attendees_on_contact_id         (contact_id)
#  index_calendar_event_attendees_on_user_id            (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (calendar_event_id => calendar_events.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (user_id => users.id)
#
class CalendarEventAttendee < ApplicationRecord
  belongs_to :calendar_event
  belongs_to :contact, optional: true
  belongs_to :user, optional: true

  RESPONSE_STATUSES = %w[pending accepted declined tentative].freeze

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :response_status, inclusion: { in: RESPONSE_STATUSES }
  validates :email, uniqueness: { scope: :calendar_event_id }

  before_validation :set_name_from_associations

  scope :accepted, -> { where(response_status: 'accepted') }
  scope :declined, -> { where(response_status: 'declined') }
  scope :pending, -> { where(response_status: 'pending') }
  scope :organizers, -> { where(is_organizer: true) }

  def accepted?
    response_status == 'accepted'
  end

  def declined?
    response_status == 'declined'
  end

  def pending?
    response_status == 'pending'
  end

  def display_name
    name.presence || email
  end

  private

  def set_name_from_associations
    return if name.present?

    self.name = user&.name || contact&.name
  end
end
