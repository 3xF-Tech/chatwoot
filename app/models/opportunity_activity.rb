# frozen_string_literal: true

# == Schema Information
#
# Table name: opportunity_activities
#
#  id               :bigint           not null, primary key
#  activity_type    :integer          default("task")
#  completed_at     :datetime
#  description      :text
#  duration_minutes :integer
#  is_done          :boolean          default(FALSE)
#  metadata         :jsonb
#  reminder_at      :datetime
#  scheduled_at     :datetime
#  title            :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  opportunity_id   :bigint           not null
#  user_id          :bigint
#
# Indexes
#
#  idx_on_opportunity_id_scheduled_at_3324f5ef08        (opportunity_id,scheduled_at)
#  index_opportunity_activities_on_account_id           (account_id)
#  index_opportunity_activities_on_opportunity_id       (opportunity_id)
#  index_opportunity_activities_on_user_id              (user_id)
#  index_opportunity_activities_on_user_id_and_is_done  (user_id,is_done)
#  index_pending_activities_on_scheduled_at             (scheduled_at) WHERE (is_done = false)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (opportunity_id => opportunities.id)
#  fk_rails_...  (user_id => users.id)
#
class OpportunityActivity < ApplicationRecord
  belongs_to :opportunity
  belongs_to :account
  belongs_to :user, optional: true

  enum activity_type: { task: 0, call: 1, meeting: 2, email: 3, note: 4, follow_up: 5 }

  validates :title, presence: true
  validates :activity_type, presence: true

  before_validation :ensure_account_id

  scope :ordered, -> { order(scheduled_at: :asc, created_at: :desc) }
  scope :pending, -> { where(is_done: false) }
  scope :completed, -> { where(is_done: true) }
  scope :scheduled_between, ->(start_date, end_date) { where(scheduled_at: start_date..end_date) }
  scope :due_today, -> { where(scheduled_at: Time.current.all_day, is_done: false) }
  scope :overdue, -> { where(is_done: false).where('scheduled_at < ?', Time.current) }

  after_save :update_opportunity_last_activity

  def complete!
    update!(is_done: true, completed_at: Time.current)
  end

  def overdue?
    !is_done && scheduled_at.present? && scheduled_at < Time.current
  end

  def due_today?
    !is_done && scheduled_at.present? && scheduled_at.to_date == Time.current.to_date
  end

  private

  def ensure_account_id
    self.account_id = opportunity&.account_id
  end

  def update_opportunity_last_activity
    opportunity.update_column(:last_activity_at, Time.current)
  end
end
