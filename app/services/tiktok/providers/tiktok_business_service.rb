class Tiktok::Providers::TiktokBusinessService
  pattr_initialize [:tiktok_channel!]

  def send_message(recipient_id, message)
    @message = message

    if message.attachments.present?
      send_attachment_message(recipient_id, message)
    else
      send_text_message(recipient_id, message)
    end
  end

  def validate_provider_config?
    response = HTTParty.get(
      "#{api_base_path}/business/v1.3/account/info",
      headers: api_headers
    )
    response.success?
  end

  private

  def send_text_message(recipient_id, message)
    response = HTTParty.post(
      "#{api_base_path}/business/v1.3/chat/message/send",
      headers: api_headers,
      body: {
        to_user_id: recipient_id,
        message_type: 'text',
        text: { content: message.outgoing_content }
      }.to_json
    )

    process_response(response, message)
  end

  def send_attachment_message(recipient_id, message)
    attachment = message.attachments.first
    type = map_attachment_type(attachment.file_type)
    
    response = HTTParty.post(
      "#{api_base_path}/business/v1.3/chat/message/send",
      headers: api_headers,
      body: {
        to_user_id: recipient_id,
        message_type: type,
        "#{type}": {
          media_url: attachment.download_url,
          caption: message.outgoing_content
        }
      }.to_json
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

  def api_headers
    {
      'Authorization' => "Bearer #{tiktok_channel.access_token}",
      'Content-Type' => 'application/json'
    }
  end

  def api_base_path
    'https://business-api.tiktok.com'
  end

  def process_response(response, message)
    if response.success?
      parsed_response = response.parsed_response
      message.update!(
        source_id: parsed_response['data']['message_id'],
        status: 'sent'
      )
    else
      handle_error(response, message)
    end
  end

  def handle_error(response, message)
    error_message = response.parsed_response&.dig('error', 'message') || 'Unknown error'
    message.update!(
      external_error: error_message,
      status: 'failed'
    )
  end
end
