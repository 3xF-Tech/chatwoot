# == Schema Information
#
# Table name: agent_bots
#
#  id                  :bigint           not null, primary key
#  ai_agent_type       :string           default("assistant")
#  bot_config          :jsonb
#  bot_type            :integer          default("webhook")
#  context_prompt      :text
#  description         :string
#  enable_signature    :boolean          default(FALSE), not null
#  is_active           :boolean          default(TRUE), not null
#  name                :string
#  outgoing_url        :string
#  response_mode       :integer          default("auto_respond")
#  workflow_active     :boolean          default(FALSE)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint
#  workflow_id         :string
#  workflow_version_id :string
#
# Indexes
#
#  index_agent_bots_on_account_id   (account_id)
#  index_agent_bots_on_workflow_id  (workflow_id)
#

class AgentBot < ApplicationRecord
  include AccessTokenable
  include Avatarable

  # Response modes for AI Agent behavior
  enum response_mode: { auto_respond: 0, assist_agent: 1, manual_trigger: 2 }

  scope :accessible_to, lambda { |account|
    account_id = account&.id
    where(account_id: [nil, account_id])
  }

  scope :active, -> { where(is_active: true) }

  has_many :agent_bot_inboxes, dependent: :destroy_async
  has_many :inboxes, through: :agent_bot_inboxes
  has_many :messages, as: :sender, dependent: :nullify
  has_many :assigned_conversations, class_name: 'Conversation',
                                    foreign_key: :assignee_agent_bot_id,
                                    dependent: :nullify,
                                    inverse_of: :assignee_agent_bot
  belongs_to :account, optional: true
  enum bot_type: { webhook: 0 }

  validates :outgoing_url, length: { maximum: Limits::URL_LENGTH_LIMIT }
  validates :name, presence: true
  validates :context_prompt, length: { maximum: 10_000 }, allow_blank: true

  def available_name
    name
  end

  def push_event_data(inbox = nil)
    {
      id: id,
      name: name,
      avatar_url: avatar_url || inbox&.avatar_url,
      type: 'agent_bot',
      enable_signature: enable_signature,
      ai_agent_type: ai_agent_type
    }
  end

  def webhook_data
    {
      id: id,
      name: name,
      type: 'agent_bot',
      context_prompt: context_prompt,
      enable_signature: enable_signature,
      ai_agent_type: ai_agent_type,
      response_mode: response_mode,
      is_active: is_active,
      inbox_ids: inbox_ids
    }
  end

  # Returns the full AI agent configuration for n8n/webhook consumption
  def ai_agent_config
    {
      agent_id: id,
      agent_name: name,
      context_prompt: context_prompt,
      enable_signature: enable_signature,
      ai_agent_type: ai_agent_type,
      response_mode: response_mode,
      bot_config: bot_config,
      outgoing_url: outgoing_url
    }
  end

  def system_bot?
    account.nil?
  end

  # Check if agent is configured for a specific inbox
  def active_for_inbox?(inbox)
    is_active && agent_bot_inboxes.active.exists?(inbox_id: inbox.id)
  end

  def workflow?
    workflow_id.present?
  end

  def subscription
    return nil if account.blank? || ai_agent_type.blank?

    account.ai_agent_subscriptions.find_by(plan_id: ai_agent_type)
  end
end
