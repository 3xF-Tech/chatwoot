# frozen_string_literal: true

# == Schema Information
#
# Table name: opportunities
#
#  id                  :bigint           not null, primary key
#  actual_close_date   :date
#  currency            :string(3)        default("BRL")
#  custom_attributes   :jsonb
#  description         :text
#  expected_close_date :date
#  last_activity_at    :datetime
#  lost_reason         :string
#  name                :string           not null
#  probability         :integer          default(0)
#  source              :string
#  stage_entered_at    :datetime
#  status              :integer          default("open")
#  value               :decimal(15, 2)   default(0.0)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  company_id          :bigint
#  contact_id          :bigint
#  display_id          :integer          not null
#  owner_id            :bigint
#  pipeline_id         :bigint           not null
#  pipeline_stage_id   :bigint           not null
#  team_id             :bigint
#
# Indexes
#
#  index_opportunities_on_account_id                         (account_id)
#  index_opportunities_on_account_id_and_display_id          (account_id,display_id) UNIQUE
#  index_opportunities_on_account_id_and_status              (account_id,status)
#  index_opportunities_on_company_id                         (company_id)
#  index_opportunities_on_contact_id                         (contact_id)
#  index_opportunities_on_expected_close_date                (expected_close_date)
#  index_opportunities_on_last_activity_at                   (last_activity_at)
#  index_opportunities_on_owner_id                           (owner_id)
#  index_opportunities_on_pipeline_id                        (pipeline_id)
#  index_opportunities_on_pipeline_id_and_pipeline_stage_id  (pipeline_id,pipeline_stage_id)
#  index_opportunities_on_pipeline_stage_id                  (pipeline_stage_id)
#  index_opportunities_on_team_id                            (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (owner_id => users.id)
#  fk_rails_...  (pipeline_id => pipelines.id)
#  fk_rails_...  (pipeline_stage_id => pipeline_stages.id)
#  fk_rails_...  (team_id => teams.id)
#
class Opportunity < ApplicationRecord
  include Labelable

  belongs_to :account
  belongs_to :pipeline
  belongs_to :pipeline_stage
  belongs_to :contact, optional: true
  belongs_to :company, optional: true
  belongs_to :owner, class_name: 'User', optional: true
  belongs_to :team, optional: true

  has_many :items, class_name: 'OpportunityItem', dependent: :destroy
  has_many :activities, class_name: 'OpportunityActivity', dependent: :destroy
  has_many :opportunity_conversations, dependent: :destroy
  has_many :conversations, through: :opportunity_conversations
  has_many :stage_changes, class_name: 'OpportunityStageChange', dependent: :destroy

  enum status: { open: 0, won: 1, lost: 2, cancelled: 3 }

  validates :name, presence: true, length: { maximum: 255 }
  validates :account_id, presence: true
  validates :pipeline_id, presence: true
  validates :pipeline_stage_id, presence: true
  validates :value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :probability, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :currency, length: { maximum: 3 }

  before_validation :set_default_pipeline, on: :create
  before_validation :set_default_stage, on: :create
  before_validation :set_display_id, on: :create
  before_validation :inherit_probability_from_stage
  before_save :track_stage_change
  before_save :update_stage_entered_at
  after_create_commit :dispatch_create_event
  after_update_commit :dispatch_update_event
  after_destroy_commit :dispatch_destroy_event

  scope :ordered_by_value, ->(direction = :desc) { order(value: direction) }
  scope :ordered_by_created, ->(direction = :desc) { order(created_at: direction) }
  scope :ordered_by_expected_close, -> { order(expected_close_date: :asc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_pipeline, ->(pipeline_id) { where(pipeline_id: pipeline_id) }
  scope :by_stage, ->(stage_id) { where(pipeline_stage_id: stage_id) }
  scope :by_owner, ->(owner_id) { where(owner_id: owner_id) }
  scope :by_company, ->(company_id) { where(company_id: company_id) }
  scope :by_contact, ->(contact_id) { where(contact_id: contact_id) }

  def closed?
    won? || lost? || cancelled?
  end

  def move_to_stage!(stage, user: nil, notes: nil)
    return false if pipeline_stage_id == stage.id

    update!(pipeline_stage_id: stage.id)
  end

  def mark_won!(user: nil, notes: nil)
    return false if won?

    won_stage = pipeline.stages.won.first
    return false unless won_stage

    update!(
      status: :won,
      pipeline_stage_id: won_stage.id,
      actual_close_date: Time.current.to_date
    )
  end

  def mark_lost!(reason: nil, user: nil, notes: nil)
    return false if lost?

    lost_stage = pipeline.stages.lost.first
    return false unless lost_stage

    update!(
      status: :lost,
      pipeline_stage_id: lost_stage.id,
      actual_close_date: Time.current.to_date,
      lost_reason: reason
    )
  end

  def weighted_value
    (value * probability / 100.0).round(2)
  end

  def items_total
    items.sum(:total)
  end

  def pending_activities
    activities.where(is_done: false).order(:scheduled_at)
  end

  def completed_activities
    activities.where(is_done: true).order(completed_at: :desc)
  end

  private

  def set_default_pipeline
    return if pipeline_id.present?

    self.pipeline = Pipeline.default_for(account)
  end

  def set_default_stage
    return if pipeline_stage_id.present?
    return unless pipeline

    self.pipeline_stage = pipeline.stages.active_stages.ordered.first
  end

  def set_display_id
    return if display_id.present?

    max_display_id = account.opportunities.maximum(:display_id) || 0
    self.display_id = max_display_id + 1
  end

  def inherit_probability_from_stage
    return unless pipeline_stage_id_changed? || new_record?
    return unless pipeline_stage

    self.probability = pipeline_stage.probability
  end

  def track_stage_change
    return unless pipeline_stage_id_changed? && !new_record?

    stage_changes.build(
      account: account,
      user: Current.user,
      from_stage_id: pipeline_stage_id_was,
      to_stage_id: pipeline_stage_id,
      from_value: value_was,
      to_value: value
    )
  end

  def update_stage_entered_at
    return unless pipeline_stage_id_changed?

    self.stage_entered_at = Time.current
  end

  def dispatch_create_event
    Rails.configuration.dispatcher.dispatch(OPPORTUNITY_CREATED, Time.zone.now, opportunity: self)
  end

  def dispatch_update_event
    Rails.configuration.dispatcher.dispatch(OPPORTUNITY_UPDATED, Time.zone.now, opportunity: self)
  end

  def dispatch_destroy_event
    Rails.configuration.dispatcher.dispatch(OPPORTUNITY_DELETED, Time.zone.now, opportunity: self)
  end
end
