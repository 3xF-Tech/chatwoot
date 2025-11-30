# frozen_string_literal: true

# == Schema Information
#
# Table name: calendar_integrations
#
#  id                  :bigint           not null, primary key
#  access_token        :text
#  last_synced_at      :datetime
#  provider            :string           not null
#  provider_email      :string
#  refresh_token       :text
#  sync_settings       :jsonb
#  sync_status         :string           default("pending")
#  token_expires_at    :datetime
#  webhook_expires_at  :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  calendar_id         :string
#  provider_user_id    :string
#  user_id             :bigint           not null
#  webhook_channel_id  :string
#  webhook_resource_id :string
#
# Indexes
#
#  idx_calendar_integrations_unique           (account_id,user_id,provider) UNIQUE
#  index_calendar_integrations_on_account_id  (account_id)
#  index_calendar_integrations_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (user_id => users.id)
#
class CalendarIntegration < ApplicationRecord
  belongs_to :account
  belongs_to :user
  has_many :calendar_events, dependent: :nullify

  PROVIDERS = %w[google outlook calendly].freeze
  SYNC_STATUSES = %w[pending syncing synced error].freeze

  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :provider, uniqueness: { scope: %i[account_id user_id] }
  validates :sync_status, inclusion: { in: SYNC_STATUSES }

  scope :google, -> { where(provider: 'google') }
  scope :outlook, -> { where(provider: 'outlook') }
  scope :calendly, -> { where(provider: 'calendly') }
  scope :needs_sync, -> { where(sync_status: %w[pending error]) }

  def token_expired?
    token_expires_at.present? && token_expires_at < Time.current
  end

  def token_expiring_soon?
    token_expires_at.present? && token_expires_at < 5.minutes.from_now
  end

  def refresh_token_if_needed!
    return unless token_expired? || token_expiring_soon?

    case provider
    when 'google'
      refresh_google_token!
    when 'outlook'
      refresh_outlook_token!
    end
  end

  def connected?
    access_token.present? && refresh_token.present?
  end

  def mark_syncing!
    update!(sync_status: 'syncing')
  end

  def mark_synced!
    update!(sync_status: 'synced', last_synced_at: Time.current)
  end

  def mark_error!
    update!(sync_status: 'error')
  end

  private

  def refresh_google_token!
    service = Calendar::Providers::GoogleCalendarService.new
    tokens = service.refresh_access_token(refresh_token)

    update!(
      access_token: tokens['access_token'],
      token_expires_at: Time.current + tokens['expires_in'].to_i.seconds
    )
  end

  def refresh_outlook_token!
    service = Calendar::Providers::OutlookCalendarService.new
    tokens = service.refresh_access_token(refresh_token)

    update!(
      access_token: tokens['access_token'],
      refresh_token: tokens['refresh_token'] || refresh_token,
      token_expires_at: Time.current + tokens['expires_in'].to_i.seconds
    )
  end
end
