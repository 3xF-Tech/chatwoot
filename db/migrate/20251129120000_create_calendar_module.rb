# frozen_string_literal: true

class CreateCalendarModule < ActiveRecord::Migration[7.0]
  def change
    # Calendar integrations (Google, Outlook, Calendly)
    create_table :calendar_integrations do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true
      t.string :provider, null: false # google, outlook, calendly
      t.string :provider_user_id
      t.string :provider_email
      t.text :access_token
      t.text :refresh_token
      t.datetime :token_expires_at
      t.string :calendar_id
      t.string :webhook_channel_id
      t.string :webhook_resource_id
      t.datetime :webhook_expires_at
      t.jsonb :sync_settings, default: {}
      t.datetime :last_synced_at
      t.string :sync_status, default: 'pending'
      t.timestamps

      t.index %i[account_id user_id provider], unique: true, name: 'idx_calendar_integrations_unique'
    end

    # Calendar events
    create_table :calendar_events do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true
      t.references :calendar_integration, foreign_key: true
      t.string :external_id
      t.string :title, null: false
      t.text :description
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.boolean :all_day, default: false
      t.string :location
      t.string :meeting_url
      t.string :event_type, default: 'meeting'
      t.string :status, default: 'confirmed'
      t.string :visibility, default: 'default'
      t.jsonb :recurrence_rule
      t.string :recurrence_id
      t.jsonb :reminders, default: []
      t.jsonb :metadata, default: {}
      t.datetime :synced_at
      t.string :sync_status, default: 'local'
      t.timestamps

      t.index %i[account_id starts_at]
      t.index %i[user_id starts_at]
      t.index %i[external_id calendar_integration_id], unique: true, name: 'idx_events_external_unique'
    end

    # Calendar event attendees
    create_table :calendar_event_attendees do |t|
      t.references :calendar_event, null: false, foreign_key: true, index: true
      t.references :contact, foreign_key: true
      t.references :user, foreign_key: true
      t.string :email
      t.string :name
      t.string :response_status, default: 'pending'
      t.boolean :is_organizer, default: false
      t.boolean :is_optional, default: false
      t.timestamps
    end

    # Polymorphic links to other resources
    create_table :calendar_event_links do |t|
      t.references :calendar_event, null: false, foreign_key: true, index: true
      t.references :linkable, polymorphic: true, null: false
      t.timestamps

      t.index %i[calendar_event_id linkable_type linkable_id], unique: true, name: 'idx_event_links_unique'
    end
  end
end
