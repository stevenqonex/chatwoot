class Tiktok::WebhookTeardownService
  pattr_initialize [:tiktok_channel!]

  def perform
    # TikTok Business API webhook teardown
    # This would typically involve unregistering the webhook URL with TikTok
    Rails.logger.info "[TIKTOK] Webhook teardown completed for business_id: #{tiktok_channel.business_id}"
  end
end
