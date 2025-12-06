# frozen_string_literal: true

class Api::V1::Accounts::CalendarIntegrationsController < Api::V1::Accounts::BaseController
  before_action :fetch_integration, only: %i[show update destroy sync calendars]

  def index
    @integrations = Current.account.calendar_integrations.where(user: Current.user)
  end

  def show; end

  def auth_url
    provider = params[:provider]

    case provider
    when 'google'
      service = Calendar::Providers::GoogleCalendarService.new

      # Validate credentials are configured
      unless service.credentials_configured?
        render json: { error: 'Google Calendar credentials not configured. Please contact your administrator.' },
               status: :unprocessable_entity
        return
      end

      state = encode_state(account_id: Current.account.id, user_id: Current.user.id)
      redirect_uri = google_oauth_callback_url
      url = service.authorization_url(redirect_uri, state)
      render json: { auth_url: url }
    else
      render json: { error: 'Unsupported provider' }, status: :unprocessable_entity
    end
  end

  def oauth_callback
    provider = params[:provider]
    code = params[:code]
    state = decode_state(params[:state])

    return render json: { error: 'Invalid state' }, status: :unprocessable_entity unless state

    case provider
    when 'google'
      handle_google_callback(code, state)
    else
      render json: { error: 'Unsupported provider' }, status: :unprocessable_entity
    end
  end

  def callback
    provider = params[:provider]
    code = params[:code]

    case provider
    when 'google'
      handle_google_callback_api(code)
    else
      render json: { error: 'Unsupported provider' }, status: :unprocessable_entity
    end
  end

  def update
    @integration.update!(integration_params)
    render :show
  end

  def destroy
    # Stop webhook if exists
    if @integration.provider == 'google' && @integration.webhook_channel_id.present?
      service = Calendar::Providers::GoogleCalendarService.new
      service.stop_webhook(@integration)
    end

    @integration.destroy!
    head :ok
  end

  def sync
    Calendar::SyncJob.perform_later(@integration.id)
    render json: { message: 'Sync started' }
  end

  def calendars
    case @integration.provider
    when 'google'
      service = Calendar::Providers::GoogleCalendarService.new
      calendars = service.list_calendars(@integration)
      render json: { calendars: calendars }
    else
      render json: { calendars: [] }
    end
  end

  private

  def fetch_integration
    @integration = Current.account.calendar_integrations.find(params[:id])
  end

  def integration_params
    params.require(:calendar_integration).permit(:calendar_id, sync_settings: {})
  end

  def google_oauth_callback_url
    # Use a fixed callback URL that works for all accounts
    # The account_id and user_id are passed securely via the state parameter
    "#{ENV.fetch('FRONTEND_URL', request.base_url)}/google/calendar/callback"
  end

  def encode_state(data)
    Base64.urlsafe_encode64(data.to_json)
  end

  def decode_state(state)
    return nil unless state

    JSON.parse(Base64.urlsafe_decode64(state)).symbolize_keys
  rescue StandardError
    nil
  end

  def handle_google_callback(code, state)
    service = Calendar::Providers::GoogleCalendarService.new
    tokens = service.exchange_code_for_tokens(code, google_oauth_callback_url)

    if tokens['error']
      render json: { error: tokens['error_description'] || tokens['error'] }, status: :unprocessable_entity
      return
    end

    user_info = service.get_user_info(tokens['access_token'])

    integration = CalendarIntegration.find_or_initialize_by(
      account_id: state[:account_id],
      user_id: state[:user_id],
      provider: 'google'
    )

    integration.assign_attributes(
      access_token: tokens['access_token'],
      refresh_token: tokens['refresh_token'] || integration.refresh_token,
      token_expires_at: Time.current + tokens['expires_in'].to_i.seconds,
      provider_user_id: user_info['id'],
      provider_email: user_info['email'],
      calendar_id: 'primary',
      sync_status: 'pending'
    )

    integration.save!

    # Setup webhook for real-time sync
    begin
      webhook_url = "#{ENV.fetch('FRONTEND_URL', request.base_url)}/webhooks/calendar/google"
      service.setup_webhook(integration, webhook_url)
    rescue StandardError => e
      Rails.logger.warn("Failed to setup Google Calendar webhook: #{e.message}")
    end

    # Trigger initial sync
    Calendar::SyncJob.perform_later(integration.id)

    # Redirect to calendar page
    redirect_to "#{ENV.fetch('FRONTEND_URL', request.base_url)}/app/accounts/#{state[:account_id]}/calendar?integration=success",
                allow_other_host: true
  end

  def handle_google_callback_api(code)
    redirect_uri = google_oauth_callback_url
    service = Calendar::Providers::GoogleCalendarService.new
    tokens = service.exchange_code_for_tokens(code, redirect_uri)

    if tokens['error']
      render json: { error: tokens['error_description'] || tokens['error'] }, status: :unprocessable_entity
      return
    end

    user_info = service.get_user_info(tokens['access_token'])

    integration = CalendarIntegration.find_or_initialize_by(
      account_id: Current.account.id,
      user_id: Current.user.id,
      provider: 'google'
    )

    integration.assign_attributes(
      access_token: tokens['access_token'],
      refresh_token: tokens['refresh_token'] || integration.refresh_token,
      token_expires_at: Time.current + tokens['expires_in'].to_i.seconds,
      provider_user_id: user_info['id'],
      provider_email: user_info['email'],
      calendar_id: 'primary',
      sync_status: 'pending'
    )

    integration.save!

    # Trigger initial sync
    Calendar::SyncJob.perform_later(integration.id)

    render json: integration, status: :created
  end
end
