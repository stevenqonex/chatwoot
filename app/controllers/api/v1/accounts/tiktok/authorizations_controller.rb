class Api::V1::Accounts::Tiktok::AuthorizationsController < Api::V1::Accounts::OauthAuthorizationController
  include TiktokConcern

  def create
    # TikTok OAuth 2.0 authorization flow
    redirect_url = tiktok_client.auth_code.authorize_url(
      {
        redirect_uri: "#{base_url}/tiktok/callback",
        scope: REQUIRED_SCOPES.join(','),
        response_type: 'code',
        state: generate_tiktok_token(Current.account.id)
      }
    )
    
    if redirect_url
      render json: { success: true, url: redirect_url }
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end

  private

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end
end
