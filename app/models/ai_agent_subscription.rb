# == Schema Information
#
# Table name: ai_agent_subscriptions
#
#  id                       :bigint           not null, primary key
#  current_period_end       :datetime
#  current_period_start     :datetime
#  messages_used_this_month :integer          default(0)
#  monthly_message_limit    :integer          default(1000)
#  status                   :string           default("trial")
#  trial_ends_at            :datetime
#  trial_messages_remaining :integer          default(50)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :bigint           not null
#  plan_id                  :string           not null
#  stripe_customer_id       :string
#  stripe_price_id          :string
#  stripe_subscription_id   :string
#
# Indexes
#
#  index_ai_agent_subscriptions_on_account_id              (account_id)
#  index_ai_agent_subscriptions_on_account_id_and_plan_id  (account_id,plan_id) UNIQUE
#  index_ai_agent_subscriptions_on_stripe_subscription_id  (stripe_subscription_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class AiAgentSubscription < ApplicationRecord
  belongs_to :account

  # Status: trial, active, past_due, canceled, unpaid
  STATUSES = %w[trial active past_due canceled unpaid].freeze

  validates :plan_id, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :account_id, uniqueness: { scope: :plan_id, message: 'already has this plan' }

  scope :active, -> { where(status: %w[trial active]) }
  scope :by_plan, ->(plan_id) { where(plan_id: plan_id) }

  def self.plans_config
    @plans_config ||= YAML.load_file(
      Rails.root.join('enterprise/config/ai_agent_plans.yml')
    )['plans']
  end

  def plan_config
    self.class.plans_config[plan_id]
  end

  def plan_name
    plan_config&.dig('name') || plan_id.titleize
  end

  def active?
    %w[trial active].include?(status)
  end

  def trial?
    status == 'trial'
  end

  def messages_remaining
    if trial?
      trial_messages_remaining
    else
      [monthly_message_limit - messages_used_this_month, 0].max
    end
  end

  def can_send_message?
    return false unless active?

    messages_remaining.positive?
  end

  def record_message!
    if trial?
      decrement!(:trial_messages_remaining) if trial_messages_remaining.positive?
    else
      increment!(:messages_used_this_month)
    end
  end

  def reset_monthly_usage!
    update!(messages_used_this_month: 0)
  end

  def usage_percentage
    if trial?
      ((50 - trial_messages_remaining).to_f / 50 * 100).round
    else
      (messages_used_this_month.to_f / monthly_message_limit * 100).round
    end
  end
end
