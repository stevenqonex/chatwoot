#######################################
# To create a TikTok provider
# - Inherit this as the base class.
# - Implement `send_message` method in your child class.
# - Implement `validate_provider_config?` method in your child class.
# - Use Childclass.new(tiktok_channel: channel).perform.
######################################

class Tiktok::Providers::BaseService < Tiktok::BaseService
  
  def send_message(_recipient_id, _message)
    raise 'Overwrite this method in child class'
  end

  def validate_provider_config?
    raise 'Overwrite this method in child class'
  end

  protected

  def process_response(response, message)
    if response.success?
      parsed_response = response.parsed_response
      # TikTok API returns message_id in the response
      message_id = parsed_response.dig('data', 'message_id') || 
                   parsed_response.dig('data', 'id') || 
                   parsed_response.dig('message_id') ||
                   parsed_response.dig('id')
      
      if message_id.present?
        message.update!(
          source_id: message_id.to_s,
          status: 'sent'
        )
        Rails.logger.info "[TIKTOK] Message sent successfully: #{message_id}"
      else
        Rails.logger.warn "[TIKTOK] No message_id in response: #{parsed_response}"
        message.update!(status: 'sent')
      end
    else
      handle_error(response, message)
    end
  end

  def handle_error(response, message)
    parsed_response = response.parsed_response
    error_message = parsed_response&.dig('error', 'message') || 
                   parsed_response&.dig('error', 'log_id') ||
                   parsed_response&.dig('message') || 
                   parsed_response&.dig('error_msg') ||
                   "HTTP #{response.code}: #{response.body}"
    
    error_code = parsed_response&.dig('error', 'code') || 
                 parsed_response&.dig('code') ||
                 response.code.to_s
    
    # Check for rate limiting errors
    if response.code == 429 || error_code.to_s.include?('rate_limit')
      Rails.logger.warn "[TIKTOK] Rate limit exceeded, message will be retried later"
      message.update!(
        external_error: "Rate limit exceeded, will retry",
        status: 'failed'
      )
    else
      Rails.logger.error "[TIKTOK] Message send failed - Code: #{error_code}, Message: #{error_message}"
      message.update!(
        external_error: "#{error_code}: #{error_message}",
        status: 'failed'
      )
    end
  end
end
