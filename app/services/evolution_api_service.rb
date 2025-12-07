class EvolutionApiService
  attr_reader :api_url, :api_key, :account

  def initialize(api_url:, api_key:, account:)
    @api_url = api_url
    @api_key = api_key
    @account = account
  end

  def create_instance(params)
    instance_name = params[:instance_name]
    inbox_id = params[:inbox_id]

    # Build body - using inbox_id means Evolution will use our existing inbox
    body = {
      instanceName: instance_name,
      qrcode: true,
      integration: 'WHATSAPP-BAILEYS',
      rejectCall: params[:reject_call] || true,
      groupsIgnore: params[:groups_ignore] || true,
      alwaysOnline: params[:always_online] || true,
      readMessages: params[:read_messages] || true,
      syncFullHistory: params[:sync_full_history] || true,
      chatwootAccountId: account.id.to_s,
      chatwootToken: generate_chatwoot_token,
      chatwootUrl: ENV.fetch('FRONTEND_URL', 'http://localhost:3000'),
      chatwootSignMsg: true,
      chatwootReopenConversation: true,
      chatwootConversationPending: false
    }

    # If we have an inbox_id, use it instead of auto-create
    if inbox_id.present?
      body[:chatwootInboxId] = inbox_id.to_s
      body[:chatwootAutoCreate] = false
    else
      body[:chatwootAutoCreate] = true
      body[:chatwootInboxName] = params[:inbox_name]
    end

    response = make_request(:post, '/instance/create', body)

    if response[:success]
      {
        success: true,
        instance_name: instance_name,
        qrcode: response[:data]['qrcode'] || response[:data]['qr'],
        status: response[:data]['status'] || 'waiting'
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

  def generate_chatwoot_token
    # Generate a secure token for the Evolution API to use when connecting to Chatwoot
    # This should be a platform app token or agent bot token
    account.access_token&.token || SecureRandom.hex(16)
  end

  def make_request(method, endpoint, body = nil)
    uri = URI.parse("#{api_url}#{endpoint}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.read_timeout = 30
    http.open_timeout = 10

    request = build_request(method, uri, body)

    response = http.request(request)
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
