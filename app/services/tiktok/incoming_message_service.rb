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
    params['data'] && params['data']['message']
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
    
    @conversation.messages.create!(
      content: message_data['text']['content'],
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      message_type: :incoming,
      sender: @contact_inbox.contact,
      source_id: message_data['message_id'].to_s,
      content_attributes: { message_type: message_data['message_type'] }
    )
  end
end
