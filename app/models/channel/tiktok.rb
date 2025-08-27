# == Schema Information
#
# Table name: channel_tiktok
#
#  id                      :bigint           not null, primary key
#  business_id             :string           not null
#  access_token            :string           not null
#  expires_at              :datetime         not null
#  webhook_verify_token    :string
#  provider_config         :jsonb            default({})
#  account_id              :integer          not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_channel_tiktok_on_business_id  (business_id) UNIQUE
#  index_channel_tiktok_on_account_id   (account_id)
#

class Channel::Tiktok < ApplicationRecord
  include Channelable
  include Reauthorizable

  self.table_name = 'channel_tiktok'
  EDITABLE_ATTRS = [:business_id, :access_token, { provider_config: {} }].freeze

  validates :business_id, presence: true, uniqueness: true
  validates :access_token, presence: true
  validates :expires_at, presence: true

  after_create :setup_webhooks
  before_destroy :teardown_webhooks

  def name
    'TikTok'
  end

  def provider_service
    Tiktok::Providers::TiktokBusinessService.new(tiktok_channel: self)
  end

  delegate :send_message, to: :provider_service
  delegate :validate_provider_config?, to: :provider_service

  private

  def setup_webhooks
    Tiktok::WebhookSetupService.new(self).perform
  rescue StandardError => e
    Rails.logger.error "[TIKTOK] Webhook setup failed: #{e.message}"
    prompt_reauthorization!
  end

  def teardown_webhooks
    Tiktok::WebhookTeardownService.new(self).perform
  end
end
