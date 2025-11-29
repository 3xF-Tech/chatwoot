json.array! @conversations do |conversation|
  json.id conversation.id
  json.display_id conversation.display_id
  json.status conversation.status
  json.created_at conversation.created_at
  json.last_activity_at conversation.last_activity_at

  if conversation.inbox.present?
    json.inbox do
      json.id conversation.inbox.id
      json.name conversation.inbox.name
      json.channel_type conversation.inbox.channel_type
    end
  end

  if conversation.contact.present?
    json.contact do
      json.id conversation.contact.id
      json.name conversation.contact.name
      json.email conversation.contact.email
    end
  end

  if conversation.assignee.present?
    json.assignee do
      json.id conversation.assignee.id
      json.name conversation.assignee.name
    end
  end
end
