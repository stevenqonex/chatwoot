class Tiktok::BaseService
  pattr_initialize [:tiktok_channel!]

  protected

  def api_headers
    {
      'Access-Token' => tiktok_channel.access_token,
      'Content-Type' => 'application/json'
    }
  end

  def api_base_path
    'https://business-api.tiktok.com/open_api/v1.3'
  end

  def handle_api_error(response, error_prefix)
    parsed_response = response.parsed_response
    error_message = parsed_response&.dig('error', 'message') || 
                   parsed_response&.dig('message') || 
                   "HTTP #{response.code}: #{response.body}"
    
    Rails.logger.error "[TIKTOK] #{error_prefix}: #{error_message}"
    error_message
  end
end
