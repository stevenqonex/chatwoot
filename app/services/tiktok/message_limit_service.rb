class Tiktok::MessageLimitService
  TIKTOK_MESSAGE_LIMIT = 10
  TIKTOK_WINDOW_HOURS = 48

  def initialize(conversation)
    @conversation = conversation
  end

  def can_send_message?
    return true unless tiktok_channel?

    messages_in_window = count_outgoing_messages_in_window
    messages_in_window < TIKTOK_MESSAGE_LIMIT
  end

  def messages_remaining
    return nil unless tiktok_channel?

    messages_in_window = count_outgoing_messages_in_window
    [TIKTOK_MESSAGE_LIMIT - messages_in_window, 0].max
  end

  def window_reset_time
    return nil unless tiktok_channel?

    last_incoming_message = @conversation.messages.incoming.order(created_at: :desc).first
    return nil unless last_incoming_message

    last_incoming_message.created_at + TIKTOK_WINDOW_HOURS.hours
  end

  private

  def tiktok_channel?
    @conversation.inbox.channel_type == 'Channel::Tiktok'
  end

  def count_outgoing_messages_in_window
    return 0 unless tiktok_channel?

    last_incoming_message = @conversation.messages.incoming.order(created_at: :desc).first
    return 0 unless last_incoming_message

    window_start = last_incoming_message.created_at
    window_end = window_start + TIKTOK_WINDOW_HOURS.hours

    @conversation.messages.outgoing
                 .where(created_at: window_start..window_end)
                 .count
  end
end
