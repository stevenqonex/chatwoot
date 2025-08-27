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

    channel_tiktok.inbox.update!(name: user_details['business_name'])
    channel_tiktok
  end

  def create_channel_with_inbox(user_details)
    ActiveRecord::Base.transaction do
      expires_at = Time.current + @response.token.expires_in.seconds

      channel_tiktok = Channel::Tiktok.create!(
        access_token: @response.token.token,
        business_id: user_details['business_id'].to_s,
        account: account,
        expires_at: expires_at
      )

      account.inboxes.create!(
        account: account,
        channel: channel_tiktok,
        name: user_details['business_name']
      )

      channel_tiktok
    end
  end

  def fetch_tiktok_user_details(access_token)
    endpoint = 'https://business-api.tiktok.com/business/v1.3/account/info'
    params = {
      access_token: access_token
    }

    make_api_request(endpoint, params, 'Failed to fetch TikTok user details')
  end

  def make_api_request(endpoint, params, error_prefix)
    response = HTTParty.get(
      endpoint,
      query: params,
      headers: { 'Accept' => 'application/json' }
    )

    unless response.success?
      Rails.logger.error "#{error_prefix}. Status: #{response.code}, Body: #{response.body}"
      raise "#{error_prefix}: #{response.body}"
    end

    begin
      JSON.parse(response.body)
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
