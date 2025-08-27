class Tiktok::ImageDownloadService < Tiktok::BaseService
  pattr_initialize [:tiktok_channel!, :media_id!]

  def perform
    download_image_from_tiktok
  end

  private

  def download_image_from_tiktok
    response = HTTParty.get(
      "#{api_base_path}/business/media/download/",
      headers: api_headers,
      query: { media_id: media_id },
      timeout: 60
    )

    if response.success?
      parsed_response = response.parsed_response
      image_url = parsed_response.dig('data', 'image_url')
      
      if image_url.present?
        Rails.logger.info "[TIKTOK] Image download URL retrieved: #{image_url}"
        image_url
      else
        Rails.logger.error "[TIKTOK] No image_url in download response: #{parsed_response}"
        nil
      end
    else
      handle_download_error(response)
      nil
    end
  end

  def handle_download_error(response)
    handle_api_error(response, 'Image download failed')
  end
end
