class Tiktok::CallbacksController < ApplicationController
  include TiktokConcern

  def show
    # Check if TikTok redirected with an error
    if params[:error].present?
      handle_authorization_error
      return
    end

    process_successful_authorization
  rescue StandardError => e
    handle_error(e)
  end

  private

  def process_successful_authorization
    @response = tiktok_client.auth_code.get_token(
      oauth_code,
      redirect_uri: "#{base_url}/tiktok/callback",
      grant_type: 'authorization_code'
    )

    inbox, already_exists = find_or_create_inbox

    if already_exists
      redirect_to app_tiktok_inbox_settings_url(account_id: account_id, inbox_id: inbox.id)
    else
      redirect_to app_tiktok_inbox_agents_url(account_id: account_id, inbox_id: inbox.id)
    end
  end

  def handle_error(error)
    Rails.logger.error("TikTok Channel creation Error: #{error.message}")
    ChatwootExceptionTracker.new(error).capture_exception

    error_info = extract_error_info(error)
    redirect_to_error_page(error_info)
  end

  def extract_error_info(error)
    if error.is_a?(OAuth2::Error)
      begin
        JSON.parse(error.message)
      rescue JSON::ParseError
        { 'error_type' => 'OAuthException', 'code' => 400, 'error_message' => error.message }
      end
    else
      { 'error_type' => error.class.name, 'code' => 500, 'error_message' => error.message }
    end
  end

  def handle_authorization_error
    error_info = {
      'error_type' => params[:error] || 'authorization_error',
      'code' => 400,
      'error_message' => params[:error_description] || 'Authorization was denied'
    }

    Rails.logger.error("TikTok Authorization Error: #{error_info['error_message']}")
    redirect_to_error_page(error_info)
  end

  def redirect_to_error_page(error_info)
    redirect_to app_new_tiktok_inbox_url(
      account_id: account_id,
      error_type: error_info['error_type'],
      code: error_info['code'],
      error_message: error_info['error_message']
    )
  end

  def find_or_create_inbox
    user_details = fetch_tiktok_user_details(@response.token.token)
    channel_tiktok = find_channel_by_business_id(user_details['business_id'].to_s)
    channel_exists = channel_tiktok.present?

    if channel_tiktok
      update_channel(channel_tiktok, user_details)
    else
      channel_tiktok = create_channel_with_inbox(user_details)
    end

    channel_tiktok.reauthorized!
    [channel_tiktok.inbox, channel_exists]
  end

  def find_channel_by_business_id(business_id)
    Channel::Tiktok.find_by(business_id: business_id, account: account)
  end

  def update_channel(channel_tiktok, user_details)
    expires_at = Time.current + @response.token.expires_in.seconds

    channel_tiktok.update!(
      access_token: @response.token.token,
      expires_at: expires_at
    )

    # Extract business name from TikTok response
    business_name = user_details['business_name'] || 
                   user_details['name'] || 
                   user_details['display_name'] ||
                   user_details['username'] ||
                   'TikTok Business'

    channel_tiktok.inbox.update!(name: business_name)
    channel_tiktok
  end

  def create_channel_with_inbox(user_details)
    ActiveRecord::Base.transaction do
      expires_at = Time.current + @response.token.expires_in.seconds

      # Extract business ID from TikTok response - it might be in different fields
      business_id = user_details['business_id'] || 
                   user_details['id'] || 
                   user_details['user_id'] ||
                   user_details['account_id']
      
      # Extract business name from TikTok response
      business_name = user_details['business_name'] || 
                     user_details['name'] || 
                     user_details['display_name'] ||
                     user_details['username'] ||
                     'TikTok Business'

      channel_tiktok = Channel::Tiktok.create!(
        access_token: @response.token.token,
        business_id: business_id.to_s,
        account: account,
        expires_at: expires_at
      )

      account.inboxes.create!(
        account: account,
        channel: channel_tiktok,
        name: business_name
      )

      channel_tiktok
    end
  end

  def fetch_tiktok_user_details(access_token)
    endpoint = 'https://business-api.tiktok.com/open_api/v1.3/business/account/info'
    params = {
      access_token: access_token
    }

    Rails.logger.info "[TIKTOK] Fetching user details from: #{endpoint}"
    user_details = make_api_request(endpoint, params, 'Failed to fetch TikTok user details')
    Rails.logger.info "[TIKTOK] User details received: #{user_details.inspect}"
    
    user_details
  end

  def make_api_request(endpoint, params, error_prefix)
    headers = {
      'Accept' => 'application/json',
      'Access-Token' => params[:access_token]
    }

    # Remove access_token from query params since it's now in headers
    query_params = params.except(:access_token)

    response = HTTParty.get(
      endpoint,
      query: query_params,
      headers: headers,
      timeout: 30
    )

    unless response.success?
      Rails.logger.error "#{error_prefix}. Status: #{response.code}, Body: #{response.body}"
      raise "#{error_prefix}: HTTP #{response.code} - #{response.body}"
    end

    begin
      parsed_response = JSON.parse(response.body)
      
      # Check for TikTok API errors in the response body
      if parsed_response['error']
        error_msg = parsed_response.dig('error', 'message') || parsed_response.dig('error', 'log_id') || 'Unknown TikTok API error'
        error_code = parsed_response.dig('error', 'code') || 'UNKNOWN'
        raise "#{error_prefix}: #{error_code} - #{error_msg}"
      end
      
      parsed_response
    rescue JSON::ParserError => e
      ChatwootExceptionTracker.new(e).capture_exception
      Rails.logger.error "Invalid JSON response: #{response.body}"
      raise e
    end
  end

  def account_id
    return unless params[:state]

    verify_tiktok_token(params[:state])
  end

  def verify_tiktok_token(state)
    Redis::Alfred.get(state)
  end

  def oauth_code
    params[:code]
  end

  def account
    @account ||= Account.find(account_id)
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end
end
