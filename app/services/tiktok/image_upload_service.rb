class Tiktok::ImageUploadService < Tiktok::BaseService
  pattr_initialize [:tiktok_channel!, :attachment!]

  def perform
    upload_image_to_tiktok
  end

  private

  def upload_image_to_tiktok
    response = HTTParty.post(
      "#{api_base_path}/business/media/upload/",
      headers: upload_api_headers,
      body: {
        media: attachment.file.open,
        media_type: 'image'
      },
      timeout: 60 # Longer timeout for file uploads
    )

    if response.success?
      parsed_response = response.parsed_response
      media_id = parsed_response.dig('data', 'media_id')
      
      if media_id.present?
        Rails.logger.info "[TIKTOK] Image uploaded successfully: #{media_id}"
        media_id
      else
        Rails.logger.error "[TIKTOK] No media_id in upload response: #{parsed_response}"
        nil
      end
    else
      handle_upload_error(response)
      nil
    end
  end

  def upload_api_headers
    {
      'Access-Token' => tiktok_channel.access_token,
      # Don't set Content-Type for multipart uploads - HTTParty will set it
    }
  end

  def handle_upload_error(response)
    handle_api_error(response, 'Image upload failed')
  end
end
