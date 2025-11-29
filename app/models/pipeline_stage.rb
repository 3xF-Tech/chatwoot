# frozen_string_literal: true

# == Schema Information
#
# Table name: pipeline_stages
#
#  id           :bigint           not null, primary key
#  color        :string(7)
#  name         :string           not null
#  position     :integer          default(0)
#  probability  :integer          default(0)
#  rotting_days :integer
#  stage_type   :integer          default("active")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  pipeline_id  :bigint           not null
#
# Indexes
#
#  index_pipeline_stages_on_pipeline_id               (pipeline_id)
#  index_pipeline_stages_on_pipeline_id_and_position  (pipeline_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (pipeline_id => pipelines.id)
#
class PipelineStage < ApplicationRecord
  belongs_to :pipeline
  has_many :opportunities, dependent: :restrict_with_error
  has_many :stage_changes_from, class_name: 'OpportunityStageChange', foreign_key: :from_stage_id, dependent: :nullify, inverse_of: :from_stage
  has_many :stage_changes_to, class_name: 'OpportunityStageChange', foreign_key: :to_stage_id, dependent: :nullify, inverse_of: :to_stage

  enum stage_type: { active: 0, won: 1, lost: 2 }

  validates :name, presence: true
  validates :pipeline_id, presence: true
  validates :probability, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position) }
  scope :active_stages, -> { where(stage_type: :active) }
  scope :closed_stages, -> { where(stage_type: [:won, :lost]) }

  delegate :account, to: :pipeline

  def closed?
    won? || lost?
  end
end
