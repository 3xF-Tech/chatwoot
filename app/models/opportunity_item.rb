# frozen_string_literal: true

# == Schema Information
#
# Table name: opportunity_items
#
#  id               :bigint           not null, primary key
#  description      :text
#  discount_percent :decimal(5, 2)    default(0.0)
#  name             :string           not null
#  position         :integer          default(0)
#  quantity         :decimal(10, 2)   default(1.0)
#  total            :decimal(15, 2)   default(0.0)
#  unit_price       :decimal(15, 2)   default(0.0)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  opportunity_id   :bigint           not null
#
# Indexes
#
#  index_opportunity_items_on_account_id                   (account_id)
#  index_opportunity_items_on_opportunity_id               (opportunity_id)
#  index_opportunity_items_on_opportunity_id_and_position  (opportunity_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (opportunity_id => opportunities.id)
#
class OpportunityItem < ApplicationRecord
  belongs_to :opportunity
  belongs_to :account

  validates :name, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }
  validates :discount_percent, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  before_validation :ensure_account_id
  before_save :calculate_total

  scope :ordered, -> { order(:position) }

  private

  def ensure_account_id
    self.account_id = opportunity&.account_id
  end

  def calculate_total
    discount_multiplier = (100 - (discount_percent || 0)) / 100.0
    self.total = (quantity || 0) * (unit_price || 0) * discount_multiplier
  end
end
