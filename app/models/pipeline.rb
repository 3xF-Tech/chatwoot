# frozen_string_literal: true

# == Schema Information
#
# Table name: pipelines
#
#  id          :bigint           not null, primary key
#  description :text
#  is_default  :boolean          default(FALSE)
#  name        :string(100)      not null
#  settings    :jsonb
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Indexes
#
#  index_pipelines_on_account_default  (account_id,is_default) UNIQUE WHERE (is_default = true)
#  index_pipelines_on_account_id       (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class Pipeline < ApplicationRecord
  belongs_to :account
  has_many :stages, class_name: 'PipelineStage', dependent: :destroy
  has_many :opportunities, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 100 }
  validates :account_id, presence: true

  before_save :ensure_single_default
  after_create :create_default_stages, if: -> { stages.empty? }

  scope :ordered, -> { order(:name) }

  def self.default_for(account)
    account.pipelines.find_by(is_default: true) || account.pipelines.first
  end

  private

  def ensure_single_default
    return unless is_default? && is_default_changed?

    account.pipelines.where(is_default: true).where.not(id: id).update_all(is_default: false)
  end

  def create_default_stages
    default_stages = [
      { name: I18n.t('pipelines.default_stages.qualification'), position: 0, probability: 10, stage_type: :active, color: '#6366F1' },
      { name: I18n.t('pipelines.default_stages.proposal'), position: 1, probability: 30, stage_type: :active, color: '#8B5CF6' },
      { name: I18n.t('pipelines.default_stages.negotiation'), position: 2, probability: 60, stage_type: :active, color: '#EC4899' },
      { name: I18n.t('pipelines.default_stages.closing'), position: 3, probability: 90, stage_type: :active, color: '#F59E0B' },
      { name: I18n.t('pipelines.default_stages.won'), position: 4, probability: 100, stage_type: :won, color: '#10B981' },
      { name: I18n.t('pipelines.default_stages.lost'), position: 5, probability: 0, stage_type: :lost, color: '#EF4444' }
    ]

    default_stages.each do |stage_attrs|
      stages.create!(stage_attrs)
    end
  end
end
