# frozen_string_literal: true

class CreateOpportunitiesModule < ActiveRecord::Migration[7.1]
  def change
    # Pipelines
    create_table :pipelines do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false, limit: 100
      t.text :description
      t.boolean :is_default, default: false
      t.jsonb :settings, default: {}
      t.timestamps
    end

    add_index :pipelines, [:account_id, :is_default], unique: true, where: 'is_default = true', name: 'index_pipelines_on_account_default'

    # Pipeline Stages
    create_table :pipeline_stages do |t|
      t.references :pipeline, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, default: 0
      t.integer :probability, default: 0
      t.integer :stage_type, default: 0 # 0: active, 1: won, 2: lost
      t.integer :rotting_days
      t.string :color, limit: 7
      t.timestamps
    end

    add_index :pipeline_stages, [:pipeline_id, :position]

    # Opportunities
    create_table :opportunities do |t|
      t.references :account, null: false, foreign_key: true
      t.references :pipeline, null: false, foreign_key: true
      t.references :pipeline_stage, null: false, foreign_key: true
      t.references :contact, foreign_key: true
      t.references :company, foreign_key: true
      t.references :owner, foreign_key: { to_table: :users }
      t.references :team, foreign_key: true
      t.integer :display_id, null: false
      t.string :name, null: false
      t.text :description
      t.decimal :value, precision: 15, scale: 2, default: 0
      t.string :currency, limit: 3, default: 'BRL'
      t.integer :probability, default: 0
      t.date :expected_close_date
      t.date :actual_close_date
      t.integer :status, default: 0 # 0: open, 1: won, 2: lost, 3: cancelled
      t.string :lost_reason
      t.string :source
      t.jsonb :custom_attributes, default: {}
      t.datetime :stage_entered_at
      t.datetime :last_activity_at
      t.timestamps
    end

    add_index :opportunities, [:account_id, :display_id], unique: true
    add_index :opportunities, [:account_id, :status]
    add_index :opportunities, [:pipeline_id, :pipeline_stage_id]
    # owner_id index is already created by t.references
    add_index :opportunities, :expected_close_date
    add_index :opportunities, :last_activity_at

    # Opportunity Items (Produtos/Serviços)
    create_table :opportunity_items do |t|
      t.references :opportunity, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.decimal :quantity, precision: 10, scale: 2, default: 1
      t.decimal :unit_price, precision: 15, scale: 2, default: 0
      t.decimal :discount_percent, precision: 5, scale: 2, default: 0
      t.decimal :total, precision: 15, scale: 2, default: 0
      t.integer :position, default: 0
      t.timestamps
    end

    add_index :opportunity_items, [:opportunity_id, :position]

    # Opportunity Activities (Follow-ups, Tarefas, etc.)
    create_table :opportunity_activities do |t|
      t.references :opportunity, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.integer :activity_type, default: 0
      t.string :title, null: false
      t.text :description
      t.datetime :scheduled_at
      t.datetime :completed_at
      t.boolean :is_done, default: false
      t.datetime :reminder_at
      t.integer :duration_minutes
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :opportunity_activities, [:opportunity_id, :scheduled_at]
    add_index :opportunity_activities, [:user_id, :is_done]
    add_index :opportunity_activities, :scheduled_at, where: 'is_done = false', name: 'index_pending_activities_on_scheduled_at'

    # Opportunity Conversations (Pivot)
    create_table :opportunity_conversations do |t|
      t.references :opportunity, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.datetime :created_at, null: false
    end

    add_index :opportunity_conversations, [:opportunity_id, :conversation_id], unique: true, name: 'index_opp_conversations_unique'

    # Stage Changes History
    create_table :opportunity_stage_changes do |t|
      t.references :opportunity, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.references :from_stage, foreign_key: { to_table: :pipeline_stages }
      t.references :to_stage, foreign_key: { to_table: :pipeline_stages }
      t.decimal :from_value, precision: 15, scale: 2
      t.decimal :to_value, precision: 15, scale: 2
      t.text :notes
      t.datetime :created_at, null: false
    end

    add_index :opportunity_stage_changes, [:opportunity_id, :created_at], name: 'index_opp_stage_changes_on_opp_and_created'
  end
end
