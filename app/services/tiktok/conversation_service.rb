class Tiktok::ConversationService < Tiktok::BaseService

  def get_conversations(limit: 20, cursor: nil)
    response = HTTParty.get(
      "#{api_base_path}/business/conversation/list/",
      headers: api_headers,
      query: build_query_params(limit, cursor),
      timeout: 30
    )

    if response.success?
      parsed_response = response.parsed_response
      {
        conversations: parsed_response.dig('data', 'conversations') || [],
        cursor: parsed_response.dig('data', 'cursor'),
        has_more: parsed_response.dig('data', 'has_more') || false
      }
    else
      handle_api_error(response, 'Failed to fetch conversations')
      { conversations: [], cursor: nil, has_more: false }
    end
  end

  def get_messages(conversation_id, limit: 20, cursor: nil)
    response = HTTParty.get(
      "#{api_base_path}/business/message/list/",
      headers: api_headers,
      query: build_message_query_params(conversation_id, limit, cursor),
      timeout: 30
    )

    if response.success?
      parsed_response = response.parsed_response
      {
        messages: parsed_response.dig('data', 'messages') || [],
        cursor: parsed_response.dig('data', 'cursor'),
        has_more: parsed_response.dig('data', 'has_more') || false
      }
    else
      handle_api_error(response, 'Failed to fetch messages')
      { messages: [], cursor: nil, has_more: false }
    end
  end

  private

  def build_query_params(limit, cursor)
    params = { limit: limit }
    params[:cursor] = cursor if cursor.present?
    params
  end

  def build_message_query_params(conversation_id, limit, cursor)
    params = { 
      conversation_id: conversation_id,
      limit: limit 
    }
    params[:cursor] = cursor if cursor.present?
    params
  end


end
