class Webhooks::TiktokController < ActionController::API
  include MetaTokenVerifyConcern

  def process_payload
    Rails.logger.info('TikTok webhook received events')
    Webhooks::TiktokEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end

  private

  def valid_token?(token)
    # Validate against TikTok webhook verify token
    token == GlobalConfigService.load('TIKTOK_WEBHOOK_VERIFY_TOKEN', '')
  end
end
