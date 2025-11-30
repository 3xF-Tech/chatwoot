# frozen_string_literal: true

# == Schema Information
#
# Table name: calendar_event_links
#
#  id                :bigint           not null, primary key
#  linkable_type     :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  calendar_event_id :bigint           not null
#  linkable_id       :bigint           not null
#
# Indexes
#
#  idx_event_links_unique                           (calendar_event_id,linkable_type,linkable_id) UNIQUE
#  index_calendar_event_links_on_calendar_event_id  (calendar_event_id)
#  index_calendar_event_links_on_linkable           (linkable_type,linkable_id)
#
# Foreign Keys
#
#  fk_rails_...  (calendar_event_id => calendar_events.id)
#
class CalendarEventLink < ApplicationRecord
  belongs_to :calendar_event
  belongs_to :linkable, polymorphic: true

  validates :linkable_type, inclusion: { in: %w[Opportunity Contact Company Conversation] }
  validates :calendar_event_id, uniqueness: { scope: %i[linkable_type linkable_id] }
end
