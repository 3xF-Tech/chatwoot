class Api::V1::Accounts::EvolutionInstancesController < Api::V1::Accounts::BaseController
  before_action :validate_evolution_api_config
  before_action :fetch_inbox_and_channel, only: [:show, :qrcode, :status, :disconnect, :destroy]

  def create
    ActiveRecord::Base.transaction do
      # 1. Create the WhatsApp Web channel locally first
      @channel = Channel::WhatsappWeb.create!(
        account_id: Current.account.id,
        instance_name: sanitized_instance_name,
        phone_number: instance_params[:phone_number],
        connection_status: 'connecting',
        provider_config: {
          reject_call: instance_params[:reject_call],
          groups_ignore: instance_params[:groups_ignore],
          always_online: instance_params[:always_online],
          read_messages: instance_params[:read_messages],
          sync_full_history: instance_params[:sync_full_history]
        }
      )

      # 2. Create the inbox associated with the channel
      @inbox = Current.account.inboxes.create!(
        name: instance_params[:inbox_name] || "WhatsApp #{sanitized_instance_name}",
        channel: @channel
      )

      # 3. Call Evolution API to create instance (without chatwootAutoCreate)
      result = evolution_service.create_instance_for_existing_inbox(
        instance_name: sanitized_instance_name,
        inbox_id: @inbox.id,
        phone_number: instance_params[:phone_number],
        reject_call: instance_params[:reject_call],
        groups_ignore: instance_params[:groups_ignore],
        always_online: instance_params[:always_online],
        read_messages: instance_params[:read_messages],
        sync_full_history: instance_params[:sync_full_history],
        days_limit_import_messages: instance_params[:days_limit_import_messages]
      )

      unless result[:success]
        raise StandardError, result[:error]
      end

      render json: {
        success: true,
        inbox_id: @inbox.id,
        instance_name: sanitized_instance_name,
        qrcode: result[:qrcode],
        status: 'waiting_qr'
      }, status: :created
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Validation Error: #{e.message}")
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("Evolution API Error: #{e.message}")
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  def show
    render json: {
      inbox_id: @inbox.id,
      instance_name: @channel.instance_name,
      phone_number: @channel.phone_number,
      connection_status: @channel.connection_status
    }
  end

  def qrcode
    # First check if already connected
    if @channel.connected?
      render json: { state: 'open' }
      return
    end

    result = @channel.fetch_qr_code

    if result[:success] && result[:qrcode].present?
      render json: { base64: result[:qrcode], state: 'connecting' }
    elsif result[:error]&.include?('connected')
      render json: { state: 'open' }
    else
      render json: { error: result[:error] || 'Failed to generate QR code' }, status: :unprocessable_entity
    end
  end

  def status
    result = @channel.check_connection_status

    if result[:success]
      state = @channel.connected? ? 'open' : 'close'
      render json: {
        state: state,
        connected: @channel.connected?,
        phone_number: @channel.phone_number
      }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def disconnect
    result = @channel.disconnect!

    if result[:success]
      render json: { message: 'Instance disconnected successfully' }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def destroy
    result = evolution_service.delete_instance(@channel.instance_name)

    if result[:success]
      @inbox.destroy!
      render json: { message: 'Instance and inbox deleted successfully' }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def validate_evolution_api_config
    return if evolution_api_configured?

    render json: { error: 'Evolution API is not configured' }, status: :unprocessable_entity
  end

  def evolution_api_configured?
    ENV['EVOLUTION_API_URL'].present? && ENV['EVOLUTION_API_KEY'].present?
  end

  def fetch_inbox_and_channel
    @inbox = Current.account.inboxes.find(params[:id])
    @channel = @inbox.channel

    unless @channel.is_a?(Channel::WhatsappWeb)
      render json: { error: 'Invalid channel type' }, status: :bad_request
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Inbox not found' }, status: :not_found
  end

  def evolution_service
    @evolution_service ||= EvolutionApiService.new(
      api_url: ENV.fetch('EVOLUTION_API_URL', nil),
      api_key: ENV.fetch('EVOLUTION_API_KEY', nil),
      account: Current.account,
      user: Current.user
    )
  end

  def sanitized_instance_name
    @sanitized_instance_name ||= instance_params[:instance_name]&.gsub(/\s+/, '_')&.downcase
  end

  def instance_params
    params.permit(
      :instance_name,
      :inbox_name,
      :phone_number,
      :reject_call,
      :groups_ignore,
      :always_online,
      :read_messages,
      :sync_full_history,
      :days_limit_import_messages
    )
  end
end
