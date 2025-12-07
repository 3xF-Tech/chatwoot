class CreateChannelWhatsappWeb < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_whatsapp_web do |t|
      t.string :instance_name, null: false
      t.string :phone_number
      t.string :connection_status, default: 'disconnected'
      t.jsonb :provider_config, default: {}
      t.integer :account_id, null: false
      t.jsonb :additional_attributes, default: {}

      t.timestamps
    end

    add_index :channel_whatsapp_web, :instance_name, unique: true
    add_index :channel_whatsapp_web, :account_id
    add_index :channel_whatsapp_web, :phone_number
  end
end
