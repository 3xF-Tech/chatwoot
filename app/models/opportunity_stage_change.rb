# frozen_string_literal: true

# == Schema Information
#
# Table name: opportunity_stage_changes
#
#  id             :bigint           not null, primary key
#  from_value     :decimal(15, 2)
#  notes          :text
#  to_value       :decimal(15, 2)
#  created_at     :datetime         not null
#  account_id     :bigint           not null
#  from_stage_id  :bigint
#  opportunity_id :bigint           not null
#  to_stage_id    :bigint
#  user_id        :bigint
#
# Indexes
#
#  index_opp_stage_changes_on_opp_and_created         (opportunity_id,created_at)
#  index_opportunity_stage_changes_on_account_id      (account_id)
#  index_opportunity_stage_changes_on_from_stage_id   (from_stage_id)
#  index_opportunity_stage_changes_on_opportunity_id  (opportunity_id)
#  index_opportunity_stage_changes_on_to_stage_id     (to_stage_id)
#  index_opportunity_stage_changes_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (from_stage_id => pipeline_stages.id)
#  fk_rails_...  (opportunity_id => opportunities.id)
#  fk_rails_...  (to_stage_id => pipeline_stages.id)
#  fk_rails_...  (user_id => users.id)
#
class OpportunityStageChange < ApplicationRecord
  belongs_to :opportunity
  belongs_to :account
  belongs_to :user, optional: true
  belongs_to :from_stage, class_name: 'PipelineStage', optional: true
  belongs_to :to_stage, class_name: 'PipelineStage', optional: true

  scope :ordered, -> { order(created_at: :desc) }

  def value_changed?
    from_value != to_value
  end

  def value_difference
    (to_value || 0) - (from_value || 0)
  end
end
