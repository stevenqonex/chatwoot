class Tiktok::IncomingMessageService
  pattr_initialize [:inbox!, :params!]

  def perform
    return unless valid_message?

    set_contact
    set_conversation
    create_message
  end

  private

  def valid_message?
    # TikTok sends various event types, we need to handle message events
    return false unless params['data']
    
    # Check for message events
    message_data = params.dig('data', 'message')
    return true if message_data.present?
    
    # Check for other relevant event types
    event_type = params.dig('data', 'event_type')
    ['message', 'message_received'].include?(event_type)
  end

  def set_contact
    user_id = params.dig('data', 'user', 'user_id')
    @contact_inbox = ContactInboxWithContactBuilder.new(
      source_id: user_id,
      inbox: inbox,
      contact_attributes: {
        name: params.dig('data', 'user', 'display_name') || 'TikTok User'
      }
    ).perform
  end

  def set_conversation
    @conversation = @contact_inbox.conversation || inbox.conversations.create!(
      contact_inbox: @contact_inbox,
      additional_attributes: { source: 'tiktok' }
    )
  end

  def create_message
    message_data = params['data']['message']
    message_type = message_data['message_type']
    
    message_content = extract_message_content(message_data, message_type)
    
    message = @conversation.messages.create!(
      content: message_content,
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      message_type: :incoming,
      sender: @contact_inbox.contact,
      source_id: message_data['message_id'].to_s,
      content_attributes: { 
        message_type: message_type,
        tiktok_message_data: message_data
      }
    )

    # Handle media attachments
    handle_media_attachment(message, message_data, message_type) if media_message?(message_type)
  end

  private

  def extract_message_content(message_data, message_type)
    case message_type
    when 'text'
      message_data.dig('text', 'content') || ''
    when 'image'
      message_data.dig('image', 'caption') || 'Image'
    when 'video'
      message_data.dig('video', 'caption') || 'Video'
    when 'audio'
      message_data.dig('audio', 'caption') || 'Audio'
    else
      'Message'
    end
  end

  def media_message?(message_type)
    %w[image video audio].include?(message_type)
  end

  def handle_media_attachment(message, message_data, message_type)
    media_id = message_data.dig(message_type, 'media_id')
    return unless media_id

    if message_type == 'image'
      # For images, we can download the URL using TikTok's download API
      image_url = Tiktok::ImageDownloadService.new(
        tiktok_channel: inbox.channel,
        media_id: media_id
      ).perform

      if image_url
        # Here you would typically download and attach the image to the message
        # This would require implementing attachment handling for external URLs
        Rails.logger.info "[TIKTOK] Image URL available for message #{message.id}: #{image_url}"
        message.content_attributes['image_url'] = image_url
        message.save!
      end
    else
      # For other media types, store the media_id for potential future use
      message.content_attributes['media_id'] = media_id
      message.save!
    end
  end
end
