module Enterprise::Conversations::PermissionFilterService
  def perform
    return filter_by_permissions(permissions) if user_has_custom_role?

    super
  end

  private

  def user_has_custom_role?
    user_role == 'agent' && account_user&.custom_role_id.present?
  end

  def permissions
    account_user&.permissions || []
  end

  def filter_by_permissions(permissions)
    # Permission-based filtering with hierarchy
    # conversation_manage > conversation_unassigned_manage > conversation_participating_manage
    if permissions.include?('conversation_manage')
      accessible_conversations
    elsif permissions.include?('conversation_unassigned_manage')
      filter_unassigned_and_mine
    elsif permissions.include?('conversation_participating_manage')
      accessible_conversations.assigned_to(user)
    else
      Conversation.none
    end
  end

  def filter_unassigned_and_mine
    mine = accessible_conversations.assigned_to(user)
    unassigned = accessible_conversations.unassigned

    # Include pending conversations if Captain AI is configured to show them
    if user.inboxes.any? { |inbox| inbox.captain_show_pending_conversations? }
      pending = accessible_conversations.pending_unassigned
      all_conversations = mine.or(unassigned).or(pending)
      
      Conversation.from("(#{all_conversations.to_sql}) as conversations")
                  .where(account_id: account.id)
    else
      # Original behavior
      Conversation.from("(#{mine.to_sql} UNION #{unassigned.to_sql}) as conversations")
                  .where(account_id: account.id)
    end
  end
end
