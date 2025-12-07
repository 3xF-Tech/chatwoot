# == Schema Information
#
# Table name: channel_whatsapp_web
#
#  id                    :bigint           not null, primary key
#  additional_attributes :jsonb
#  connection_status     :string           default("disconnected")
#  instance_name         :string           not null
#  phone_number          :string
#  provider_config       :jsonb
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :integer          not null
#
# Indexes
#
#  index_channel_whatsapp_web_on_account_id     (account_id)
#  index_channel_whatsapp_web_on_instance_name  (instance_name) UNIQUE
#  index_channel_whatsapp_web_on_phone_number   (phone_number)
#

class Channel::WhatsappWeb < ApplicationRecord
  include Channelable
  include Reauthorizable

  self.table_name = 'channel_whatsapp_web'

  EDITABLE_ATTRS = [:instance_name, :phone_number, :connection_status, { provider_config: {}, additional_attributes: {} }].freeze

  CONNECTION_STATUSES = %w[disconnected connecting connected error].freeze

  validates :instance_name, presence: true, uniqueness: true
  validates :connection_status, inclusion: { in: CONNECTION_STATUSES }

  before_validation :sanitize_instance_name

  def name
    'WhatsApp Web'
  end

  def provider
    'evolution_api'
  end

  def connected?
    connection_status == 'connected'
  end

  def disconnected?
    connection_status == 'disconnected'
  end

  def evolution_api_url
    ENV.fetch('EVOLUTION_API_URL', nil)
  end

  def evolution_api_key
    ENV.fetch('EVOLUTION_API_KEY', nil)
  end

  def evolution_service
    @evolution_service ||= EvolutionApiService.new(
      api_url: evolution_api_url,
      api_key: evolution_api_key,
      account: account
    )
  end

  def fetch_qr_code
    return { success: false, error: 'Already connected' } if connected?

    evolution_service.get_qrcode(instance_name)
  end

  def check_connection_status
    result = evolution_service.get_connection_status(instance_name)

    if result[:success]
      new_status = result[:connected] ? 'connected' : 'disconnected'
      update(connection_status: new_status)
      update(phone_number: result[:phone_number]) if result[:phone_number].present?
    end

    result
  end

  def disconnect!
    result = evolution_service.disconnect_instance(instance_name)
    update(connection_status: 'disconnected') if result[:success]
    result
  end

  private

  def sanitize_instance_name
    self.instance_name = instance_name&.gsub(/\s+/, '_')&.downcase
  end
end
