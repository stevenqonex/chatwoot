module TiktokConcern
  extend ActiveSupport::Concern

  REQUIRED_SCOPES = %w[user.info.basic chat.message].freeze

  def tiktok_client
    ::OAuth2::Client.new(
      client_id,
      client_secret,
      {
        site: 'https://business-api.tiktok.com',
        authorize_url: 'https://business-api.tiktok.com/oauth/authorize',
        token_url: 'https://business-api.tiktok.com/oauth/access_token',
        auth_scheme: :request_body,
        token_method: :post
      }
    )
  end

  def generate_tiktok_token(account_id)
    # Generate a secure token for state parameter
    token = SecureRandom.hex(16)
    Redis::Alfred.setex(token, 10.minutes, account_id)
    token
  end

  private

  def client_id
    GlobalConfigService.load('TIKTOK_APP_ID', nil)
  end

  def client_secret
    GlobalConfigService.load('TIKTOK_APP_SECRET', nil)
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end
end
