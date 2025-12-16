class AddWorkflowIdToAgentBots < ActiveRecord::Migration[7.1]
  def change
    add_column :agent_bots, :workflow_id, :string
    add_column :agent_bots, :workflow_version_id, :string
    add_column :agent_bots, :workflow_active, :boolean, default: false
    add_index :agent_bots, :workflow_id
  end
end
