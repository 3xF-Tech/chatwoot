# frozen_string_literal: true

class AddAiAgentFieldsToAgentBots < ActiveRecord::Migration[7.0]
  def change
    # Add context_prompt for LLM system prompt / business context
    add_column :agent_bots, :context_prompt, :text

    # Add enable_signature to control if agent signs messages
    add_column :agent_bots, :enable_signature, :boolean, default: false, null: false

    # Add ai_agent_type for future marketplace categorization
    add_column :agent_bots, :ai_agent_type, :string, default: 'assistant'

    # Add response_mode for controlling agent behavior
    add_column :agent_bots, :response_mode, :integer, default: 0

    # Add is_active flag for enabling/disabling agent
    add_column :agent_bots, :is_active, :boolean, default: true, null: false
  end
end
