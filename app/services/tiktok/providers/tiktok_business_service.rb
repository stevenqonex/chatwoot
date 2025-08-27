class Tiktok::Providers::TiktokBusinessService < Tiktok::Providers::BaseService

  def send_message(recipient_id, message)
    @message = message

    # Check TikTok message limits before sending
    limit_service = Tiktok::MessageLimitService.new(message.conversation)
    unless limit_service.can_send_message?
      handle_message_limit_exceeded(message, limit_service)
      return
    end

    # Validate message content for TikTok constraints
    unless valid_message_content?(message)
      handle_invalid_content(message)
      return
    end

    if message.attachments.present?
      send_attachment_message(recipient_id, message)
    else
      send_text_message(recipient_id, message)
    end
  end

  def validate_provider_config?
    response = HTTParty.get(
      "#{api_base_path}/business/account/info",
      headers: api_headers
    )
    response.success?
  end

  private

  def send_text_message(recipient_id, message)
    response = HTTParty.post(
      "#{api_base_path}/business/message/send/",
      headers: api_headers,
      body: {
        to_user_id: recipient_id,
        message_type: 'text',
        content: {
          text: message.outgoing_content
        }
      }.to_json,
      timeout: 30
    )

    process_response(response, message)
  end

  def send_attachment_message(recipient_id, message)
    attachment = message.attachments.first
    type = map_attachment_type(attachment.file_type)
    
    # For images, upload to TikTok first to get media_id
    if type == 'image'
      media_id = Tiktok::ImageUploadService.new(
        tiktok_channel: tiktok_channel,
        attachment: attachment
      ).perform
      
      unless media_id
        handle_upload_failed(message)
        return
      end
      
      send_image_message_with_media_id(recipient_id, message, media_id)
    else
      # For other types, use direct URL (if supported)
      send_media_message_with_url(recipient_id, message, type, attachment)
    end
  end

  def send_image_message_with_media_id(recipient_id, message, media_id)
    response = HTTParty.post(
      "#{api_base_path}/business/message/send/",
      headers: api_headers,
      body: {
        to_user_id: recipient_id,
        message_type: 'image',
        content: {
          image: {
            media_id: media_id,
            caption: message.outgoing_content
          }
        }
      }.to_json,
      timeout: 30
    )

    process_response(response, message)
  end

  def send_media_message_with_url(recipient_id, message, type, attachment)
    response = HTTParty.post(
      "#{api_base_path}/business/message/send/",
      headers: api_headers,
      body: {
        to_user_id: recipient_id,
        message_type: type,
        content: {
          "#{type}": {
            media_url: attachment.download_url,
            caption: message.outgoing_content
          }
        }
      }.to_json,
      timeout: 30
    )

    process_response(response, message)
  end

  def map_attachment_type(file_type)
    case file_type
    when 'image' then 'image'
    when 'video' then 'video'
    when 'audio' then 'audio'
    else 'file'
    end
  end





  private

  def valid_message_content?(message)
    # TikTok text message limit: 6,000 characters
    return false if message.content.length > 6000

    # Check attachment constraints
    if message.attachments.present?
      attachment = message.attachments.first
      
      # Only JPG and PNG images up to 3MB are supported
      if attachment.file_type == 'image'
        return false unless %w[jpg jpeg png].include?(attachment.file.filename.extension.downcase)
        return false if attachment.file.byte_size > 3.megabytes
      elsif %w[video audio].include?(attachment.file_type)
        # Video and voice messages are not supported
        return false
      end
    end

    true
  end

  def handle_message_limit_exceeded(message, limit_service)
    reset_time = limit_service.window_reset_time
    reset_time_str = reset_time&.strftime('%Y-%m-%d %H:%M:%S UTC') || 'unknown'
    
    Rails.logger.warn "[TIKTOK] Message limit exceeded (10 messages per 48h window). Window resets at: #{reset_time_str}"
    message.update!(
      external_error: "TikTok message limit exceeded (10 messages per 48h). Window resets at: #{reset_time_str}",
      status: 'failed'
    )
  end

  def handle_invalid_content(message)
    Rails.logger.warn "[TIKTOK] Invalid message content - exceeds TikTok constraints"
    message.update!(
      external_error: "Message content exceeds TikTok limits (6000 chars for text, JPG/PNG images up to 3MB only)",
      status: 'failed'
    )
  end

  def handle_upload_failed(message)
    Rails.logger.error "[TIKTOK] Image upload failed - cannot send message"
    message.update!(
      external_error: "Failed to upload image to TikTok",
      status: 'failed'
    )
  end
end
