class CreateAiAgentSubscriptions < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_agent_subscriptions do |t|
      t.references :account, null: false, foreign_key: true
      t.string :plan_id, null: false
      t.string :stripe_subscription_id
      t.string :stripe_customer_id
      t.string :stripe_price_id
      t.string :status, default: 'trial'
      t.integer :monthly_message_limit, default: 1000
      t.integer :trial_messages_remaining, default: 50
      t.integer :messages_used_this_month, default: 0
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :trial_ends_at

      t.timestamps
    end

    add_index :ai_agent_subscriptions, :stripe_subscription_id, unique: true
    add_index :ai_agent_subscriptions, [:account_id, :plan_id], unique: true
  end
end
