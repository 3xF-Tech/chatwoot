class EvolutionApiService
  attr_reader :api_url, :api_key, :account, :user

  def initialize(api_url:, api_key:, account:, user:)
    @api_url = api_url
    @api_key = api_key
    @account = account
    @user = user
  end

  def create_instance(params)
    instance_name = params[:instance_name]
    # Remove + from phone number - Evolution API expects just digits
    phone_number = params[:phone_number]&.gsub(/^\+/, '')

    # Build body with all required fields for Evolution API
    body = {
      # Instance configuration
      instanceName: instance_name,
      number: phone_number,
      qrcode: true,
      integration: 'WHATSAPP-BAILEYS',

      # Settings
      rejectCall: params[:reject_call].nil? || params[:reject_call],
      groupsIgnore: params[:groups_ignore].nil? || params[:groups_ignore],
      alwaysOnline: params[:always_online].nil? || params[:always_online],
      readMessages: params[:read_messages].nil? || params[:read_messages],
      readStatus: false,
      syncFullHistory: params[:sync_full_history].nil? || params[:sync_full_history],

      # Chatwoot integration
      chatwootAccountId: account.id.to_s,
      chatwootToken: user_access_token,
      chatwootUrl: chatwoot_url,
      chatwootSignMsg: true,
      chatwootReopenConversation: true,
      chatwootConversationPending: true,
      chatwootImportContacts: true,
      chatwootNameInbox: params[:inbox_name],
      chatwootMergeBrazilContacts: true,
      chatwootImportMessages: true,
      chatwootDaysLimitImportMessages: params[:days_limit_import_messages] || 90,
      chatwootOrganization: account.name,
      chatwootAutoCreate: true
    }

    Rails.logger.info("Evolution API - Creating instance: #{instance_name}")
    Rails.logger.info("Evolution API - Request body: #{body.to_json}")

    response = make_request(:post, '/instance/create', body)

    Rails.logger.info("Evolution API - Response: #{response.inspect}")

    if response[:success]
      # Extract QR code from different possible response formats
      qrcode_data = response[:data]['qrcode']
      qrcode_data ||= response[:data].dig('qrcode', 'base64')
      qrcode_data ||= response[:data]['base64']

      {
        success: true,
        instance_name: instance_name,
        qrcode: qrcode_data,
        status: response[:data]['state'] || response[:data]['status'] || 'waiting'
      }
    else
      { success: false, error: response[:error] }
    end
  rescue StandardError => e
    { success: false, error: e.message }
  end

  # Create instance for an existing inbox (without chatwootAutoCreate)
  # This is used when the inbox is created locally first
  def create_instance_for_existing_inbox(params)
    instance_name = params[:instance_name]
    phone_number = params[:phone_number]&.gsub(/^\+/, '')

    # Build body WITHOUT chatwootAutoCreate - we already have the inbox
    body = {
      instanceName: instance_name,
      number: phone_number,
      qrcode: true,
      integration: 'WHATSAPP-BAILEYS',

      # Settings
      rejectCall: params[:reject_call].nil? || params[:reject_call],
      groupsIgnore: params[:groups_ignore].nil? || params[:groups_ignore],
      alwaysOnline: params[:always_online].nil? || params[:always_online],
      readMessages: params[:read_messages].nil? || params[:read_messages],
      readStatus: false,
      syncFullHistory: params[:sync_full_history].nil? || params[:sync_full_history],

      # Chatwoot integration - connect to existing inbox
      chatwootAccountId: account.id.to_s,
      chatwootToken: user_access_token,
      chatwootUrl: chatwoot_url,
      chatwootSignMsg: true,
      chatwootReopenConversation: true,
      chatwootConversationPending: true,
      chatwootImportContacts: true,
      chatwootMergeBrazilContacts: true,
      chatwootImportMessages: true,
      chatwootDaysLimitImportMessages: params[:days_limit_import_messages] || 90,
      chatwootOrganization: account.name,
      # IMPORTANT: Do NOT auto-create inbox - we already created it
      chatwootAutoCreate: false,
      # Link to existing inbox
      chatwootInboxId: params[:inbox_id].to_s
    }

    Rails.logger.info("Evolution API - Creating instance for existing inbox: #{instance_name}")
    Rails.logger.info("Evolution API - Inbox ID: #{params[:inbox_id]}")

    response = make_request(:post, '/instance/create', body)

    if response[:success]
      qrcode_data = response[:data]['qrcode']
      qrcode_data ||= response[:data].dig('qrcode', 'base64')
      qrcode_data ||= response[:data]['base64']

      {
        success: true,
        instance_name: instance_name,
        qrcode: qrcode_data,
        status: response[:data]['state'] || response[:data]['status'] || 'waiting'
      }
    else
      { success: false, error: response[:error] }
    end
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def get_qrcode(instance_name)
    response = make_request(:get, "/instance/connect/#{instance_name}")

    if response[:success]
      {
        success: true,
        qrcode: response[:data]['qrcode'] || response[:data]['qr'] || response[:data]['base64']
      }
    else
      { success: false, error: response[:error] }
    end
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def get_connection_status(instance_name)
    response = make_request(:get, "/instance/connectionState/#{instance_name}")

    if response[:success]
      state = response[:data]['state'] || response[:data]['instance']&.dig('state')
      {
        success: true,
        status: state,
        connected: state == 'open' || state == 'connected'
      }
    else
      { success: false, error: response[:error] }
    end
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def disconnect_instance(instance_name)
    response = make_request(:delete, "/instance/logout/#{instance_name}")

    if response[:success]
      { success: true }
    else
      { success: false, error: response[:error] }
    end
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def delete_instance(instance_name)
    response = make_request(:delete, "/instance/delete/#{instance_name}")

    if response[:success]
      { success: true }
    else
      { success: false, error: response[:error] }
    end
  rescue StandardError => e
    { success: false, error: e.message }
  end

  private

  def user_access_token
    # Use the current user's access token for Chatwoot API integration
    user.access_token&.token || raise('User access token not found')
  end

  def chatwoot_url
    # Get the Chatwoot URL from environment, ensuring it ends without trailing slash
    url = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
    url.chomp('/')
  end

  def make_request(method, endpoint, body = nil)
    uri = URI.parse("#{api_url}#{endpoint}")

    # Log detalhado da requisição
    Rails.logger.info('=' * 80)
    Rails.logger.info('EVOLUTION API REQUEST DEBUG')
    Rails.logger.info('=' * 80)
    Rails.logger.info("Method: #{method.upcase}")
    Rails.logger.info("Full URL: #{uri}")
    Rails.logger.info("Host: #{uri.host}")
    Rails.logger.info("Port: #{uri.port}")
    Rails.logger.info("Path: #{uri.request_uri}")
    Rails.logger.info("SSL: #{uri.scheme == 'https'}")
    Rails.logger.info("API Key: #{api_key[0..15]}...") if api_key
    Rails.logger.info('-' * 40)
    Rails.logger.info('Request Body (JSON):')
    Rails.logger.info(body.to_json) if body
    Rails.logger.info('-' * 40)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.read_timeout = 30
    http.open_timeout = 10

    request = build_request(method, uri, body)

    # Log headers
    Rails.logger.info('Request Headers:')
    request.each_header { |k, v| Rails.logger.info("  #{k}: #{v}") }
    Rails.logger.info('-' * 40)

    response = http.request(request)

    # Log detalhado da resposta
    Rails.logger.info('EVOLUTION API RESPONSE DEBUG')
    Rails.logger.info("Response Code: #{response.code}")
    Rails.logger.info("Response Message: #{response.message}")
    Rails.logger.info('Response Body:')
    Rails.logger.info(response.body)
    Rails.logger.info('=' * 80)

    parse_response(response)
  end

  def build_request(method, uri, body)
    request = case method
              when :get
                Net::HTTP::Get.new(uri.request_uri)
              when :post
                Net::HTTP::Post.new(uri.request_uri)
              when :delete
                Net::HTTP::Delete.new(uri.request_uri)
              else
                raise ArgumentError, "Unsupported HTTP method: #{method}"
              end

    request['Content-Type'] = 'application/json'
    request['apikey'] = api_key

    request.body = body.to_json if body.present?

    request
  end

  def parse_response(response)
    case response.code.to_i
    when 200, 201
      { success: true, data: JSON.parse(response.body) }
    when 400
      { success: false, error: 'Bad request' }
    when 401
      { success: false, error: 'Unauthorized - check API key' }
    when 404
      { success: false, error: 'Instance not found' }
    else
      error_message = begin
        JSON.parse(response.body)['message']
      rescue StandardError
        response.body
      end
      { success: false, error: error_message || "HTTP #{response.code}" }
    end
  rescue JSON::ParserError
    { success: false, error: 'Invalid response from Evolution API' }
  end
end
