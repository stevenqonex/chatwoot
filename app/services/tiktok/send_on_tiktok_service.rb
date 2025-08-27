class Tiktok::SendOnTiktokService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Tiktok
  end

  def perform_reply
    recipient_id = contact_inbox.source_id
    channel.provider_service.send_message(recipient_id, message)
  end
end
