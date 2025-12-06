# frozen_string_literal: true

class Google::CalendarCallbacksController < ApplicationController
  include GoogleConcern

  # This is a fixed callback URL for Google Calendar OAuth
  # The account_id and user_id are passed via the state parameter (signed)
  # This allows a single callback URL to work for all accounts

  def show
    state = decode_state(params[:state])

    if state.blank?
      redirect_to_error('Invalid or expired authorization state')
      return
    end

    account = Account.find_by(id: state[:account_id])
    user = User.find_by(id: state[:user_id])

    if account.blank? || user.blank?
      redirect_to_error('Account or user not found')
      return
    end

    # Exchange code for tokens
    service = Calendar::Providers::GoogleCalendarService.new
    tokens = service.exchange_code_for_tokens(params[:code], google_calendar_callback_url)

    if tokens['error']
      redirect_to_error(tokens['error_description'] || tokens['error'])
      return
    end

    # Get user info from Google
    user_info = service.get_user_info(tokens['access_token'])

    # Find or create the calendar integration
    integration = account.calendar_integrations.find_or_initialize_by(
      user: user,
      provider: 'google',
      provider_user_id: user_info['id']
    )

    integration.update!(
      email: user_info['email'],
      access_token: tokens['access_token'],
      refresh_token: tokens['refresh_token'] || integration.refresh_token,
      token_expires_at: Time.current + tokens['expires_in'].to_i.seconds,
      sync_enabled: true
    )

    # Redirect to the calendar settings page
    redirect_to success_redirect_url(account, integration),
                allow_other_host: true
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    redirect_to_error('An error occurred during authorization')
  end

  private

  def google_calendar_callback_url
    "#{ENV.fetch('FRONTEND_URL', request.base_url)}/google/calendar/callback"
  end

  def decode_state(state)
    return nil if state.blank?

    JSON.parse(Base64.urlsafe_decode64(state)).symbolize_keys
  rescue StandardError
    nil
  end

  def redirect_to_error(message)
    frontend_url = ENV.fetch('FRONTEND_URL', '')
    redirect_to "#{frontend_url}/app/login?error=#{ERB::Util.url_encode(message)}",
                allow_other_host: true
  end

  def success_redirect_url(account, integration)
    frontend_url = ENV.fetch('FRONTEND_URL', '')
    "#{frontend_url}/app/accounts/#{account.id}/calendar/settings?connected=true&integration_id=#{integration.id}"
  end
end
