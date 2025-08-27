class Tiktok::WebhookSetupService
  pattr_initialize [:tiktok_channel!]

  def perform
    # TikTok Business API webhook setup
    # This would typically involve registering the webhook URL with TikTok
    # For now, we'll just ensure the verify token is set
    ensure_webhook_verify_token
    
    Rails.logger.info "[TIKTOK] Webhook setup completed for business_id: #{tiktok_channel.business_id}"
  end

  private

  def ensure_webhook_verify_token
    return if tiktok_channel.webhook_verify_token.present?

    tiktok_channel.update!(
      webhook_verify_token: SecureRandom.hex(16)
    )
  end
end
