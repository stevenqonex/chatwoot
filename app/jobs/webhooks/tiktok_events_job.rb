class Webhooks::TiktokEventsJob < ApplicationJob
  queue_as :low

  def perform(params = {})
    channel = find_channel_from_payload(params)
    return unless channel&.active?

    Tiktok::IncomingMessageService.new(inbox: channel.inbox, params: params).perform
  end

  private

  def find_channel_from_payload(params)
    business_id = params.dig('data', 'business_id')
    return unless business_id

    Channel::Tiktok.find_by(business_id: business_id)
  end
end
