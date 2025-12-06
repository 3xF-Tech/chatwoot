# frozen_string_literal: true

class Calendar::Providers::GoogleCalendarService
  GOOGLE_AUTH_URL = 'https://accounts.google.com/o/oauth2/v2/auth'
  GOOGLE_TOKEN_URL = 'https://oauth2.googleapis.com/token'
  CALENDAR_API_BASE = 'https://www.googleapis.com/calendar/v3'
  SCOPES = %w[
    https://www.googleapis.com/auth/calendar
    https://www.googleapis.com/auth/calendar.events
    https://www.googleapis.com/auth/userinfo.email
  ].freeze

  def credentials_configured?
    google_client_id.present? && google_client_secret.present?
  end

  def authorization_url(redirect_uri, state)
    params = {
      client_id: google_client_id,
      redirect_uri: redirect_uri,
      response_type: 'code',
      scope: SCOPES.join(' '),
      access_type: 'offline',
      prompt: 'consent',
      state: state
    }
    "#{GOOGLE_AUTH_URL}?#{params.to_query}"
  end

  def exchange_code_for_tokens(code, redirect_uri)
    response = HTTParty.post(GOOGLE_TOKEN_URL, {
                               body: {
                                 client_id: google_client_id,
                                 client_secret: google_client_secret,
                                 code: code,
                                 grant_type: 'authorization_code',
                                 redirect_uri: redirect_uri
                               }
                             })
    JSON.parse(response.body)
  end

  def refresh_access_token(refresh_token)
    response = HTTParty.post(GOOGLE_TOKEN_URL, {
                               body: {
                                 client_id: google_client_id,
                                 client_secret: google_client_secret,
                                 refresh_token: refresh_token,
                                 grant_type: 'refresh_token'
                               }
                             })
    JSON.parse(response.body)
  end

  def get_user_info(access_token)
    response = HTTParty.get('https://www.googleapis.com/oauth2/v2/userinfo', {
                              headers: auth_headers(access_token)
                            })
    JSON.parse(response.body)
  end

  def list_calendars(integration)
    integration.refresh_token_if_needed!

    response = HTTParty.get(
      "#{CALENDAR_API_BASE}/users/me/calendarList",
      headers: auth_headers(integration.access_token)
    )
    data = JSON.parse(response.body)
    data['items'] || []
  end

  def fetch_events(integration, time_min:, time_max:)
    integration.refresh_token_if_needed!

    calendar_id = integration.calendar_id || 'primary'
    response = HTTParty.get(
      "#{CALENDAR_API_BASE}/calendars/#{CGI.escape(calendar_id)}/events",
      headers: auth_headers(integration.access_token),
      query: {
        timeMin: time_min.iso8601,
        timeMax: time_max.iso8601,
        singleEvents: true,
        orderBy: 'startTime',
        maxResults: 250
      }
    )

    data = JSON.parse(response.body)
    parse_events(data['items'] || [])
  end

  def create_event(integration, calendar_event)
    integration.refresh_token_if_needed!

    calendar_id = integration.calendar_id || 'primary'
    response = HTTParty.post(
      "#{CALENDAR_API_BASE}/calendars/#{CGI.escape(calendar_id)}/events",
      headers: auth_headers(integration.access_token).merge('Content-Type' => 'application/json'),
      body: build_event_payload(calendar_event).to_json
    )

    data = JSON.parse(response.body)
    data['id']
  end

  def update_event(integration, calendar_event)
    integration.refresh_token_if_needed!

    calendar_id = integration.calendar_id || 'primary'
    HTTParty.patch(
      "#{CALENDAR_API_BASE}/calendars/#{CGI.escape(calendar_id)}/events/#{calendar_event.external_id}",
      headers: auth_headers(integration.access_token).merge('Content-Type' => 'application/json'),
      body: build_event_payload(calendar_event).to_json
    )
  end

  def delete_event(integration, external_id)
    integration.refresh_token_if_needed!

    calendar_id = integration.calendar_id || 'primary'
    HTTParty.delete(
      "#{CALENDAR_API_BASE}/calendars/#{CGI.escape(calendar_id)}/events/#{external_id}",
      headers: auth_headers(integration.access_token)
    )
  end

  def setup_webhook(integration, callback_url)
    integration.refresh_token_if_needed!

    calendar_id = integration.calendar_id || 'primary'
    channel_id = SecureRandom.uuid

    response = HTTParty.post(
      "#{CALENDAR_API_BASE}/calendars/#{CGI.escape(calendar_id)}/events/watch",
      headers: auth_headers(integration.access_token).merge('Content-Type' => 'application/json'),
      body: {
        id: channel_id,
        type: 'web_hook',
        address: callback_url,
        expiration: (7.days.from_now.to_i * 1000).to_s
      }.to_json
    )

    data = JSON.parse(response.body)

    integration.update!(
      webhook_channel_id: channel_id,
      webhook_resource_id: data['resourceId'],
      webhook_expires_at: Time.zone.at(data['expiration'].to_i / 1000)
    )

    data
  end

  def stop_webhook(integration)
    return if integration.webhook_channel_id.blank?

    HTTParty.post(
      "#{CALENDAR_API_BASE}/channels/stop",
      headers: auth_headers(integration.access_token).merge('Content-Type' => 'application/json'),
      body: {
        id: integration.webhook_channel_id,
        resourceId: integration.webhook_resource_id
      }.to_json
    )

    integration.update!(
      webhook_channel_id: nil,
      webhook_resource_id: nil,
      webhook_expires_at: nil
    )
  end

  private

  def google_client_id
    # Try calendar-specific first, then fall back to general OAuth credentials
    GlobalConfigService.load('GOOGLE_CALENDAR_CLIENT_ID', nil) ||
      ENV.fetch('GOOGLE_CALENDAR_CLIENT_ID', nil) ||
      GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_ID', nil) ||
      ENV.fetch('GOOGLE_OAUTH_CLIENT_ID', nil)
  end

  def google_client_secret
    # Try calendar-specific first, then fall back to general OAuth credentials
    GlobalConfigService.load('GOOGLE_CALENDAR_CLIENT_SECRET', nil) ||
      ENV.fetch('GOOGLE_CALENDAR_CLIENT_SECRET', nil) ||
      GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_SECRET', nil) ||
      ENV.fetch('GOOGLE_OAUTH_CLIENT_SECRET', nil)
  end

  def auth_headers(access_token)
    { 'Authorization' => "Bearer #{access_token}" }
  end

  def build_event_payload(event)
    payload = {
      summary: event.title,
      description: event.description,
      location: event.location,
      status: event.status
    }

    if event.all_day?
      payload[:start] = { date: event.starts_at.to_date.iso8601 }
      payload[:end] = { date: (event.ends_at.to_date + 1.day).iso8601 }
    else
      payload[:start] = { dateTime: event.starts_at.iso8601, timeZone: 'America/Sao_Paulo' }
      payload[:end] = { dateTime: event.ends_at.iso8601, timeZone: 'America/Sao_Paulo' }
    end

    payload[:attendees] = event.attendees.map { |a| { email: a.email, displayName: a.name } } if event.attendees.any?

    if event.meeting_url.present?
      payload[:conferenceData] = {
        entryPoints: [{ entryPointType: 'video', uri: event.meeting_url }]
      }
    end

    payload
  end

  def parse_events(items)
    items.map do |item|
      {
        id: item['id'],
        title: item['summary'] || '(Sem título)',
        description: item['description'],
        starts_at: parse_datetime(item['start']),
        ends_at: parse_datetime(item['end']),
        all_day: item.dig('start', 'date').present?,
        location: item['location'],
        status: item['status'] || 'confirmed',
        meeting_url: extract_meeting_url(item),
        attendees: parse_attendees(item['attendees'] || []),
        metadata: {
          html_link: item['htmlLink'],
          hangout_link: item['hangoutLink'],
          creator: item['creator'],
          organizer: item['organizer']
        }
      }
    end
  end

  def parse_datetime(datetime_hash)
    return nil unless datetime_hash

    if datetime_hash['dateTime']
      Time.zone.parse(datetime_hash['dateTime'])
    elsif datetime_hash['date']
      Date.parse(datetime_hash['date']).beginning_of_day
    end
  end

  def parse_attendees(attendees)
    attendees.map do |attendee|
      {
        email: attendee['email'],
        name: attendee['displayName'],
        response_status: attendee['responseStatus'],
        is_organizer: attendee['organizer'] == true,
        is_optional: attendee['optional'] == true
      }
    end
  end

  def extract_meeting_url(item)
    item['hangoutLink'] ||
      item.dig('conferenceData', 'entryPoints')&.find { |entry| entry['entryPointType'] == 'video' }&.dig('uri')
  end
end
