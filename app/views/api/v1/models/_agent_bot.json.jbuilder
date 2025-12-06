json.id resource.id
json.name resource.name
json.description resource.description
json.thumbnail resource.avatar_url
json.outgoing_url resource.outgoing_url unless resource.system_bot?
json.bot_type resource.bot_type
json.bot_config resource.bot_config
json.account_id resource.account_id
json.access_token resource.access_token if resource.access_token.present?
json.system_bot resource.system_bot?

# AI Agent fields
json.context_prompt resource.context_prompt
json.enable_signature resource.enable_signature
json.ai_agent_type resource.ai_agent_type
json.response_mode resource.response_mode
json.is_active resource.is_active

# Associated inboxes
json.inbox_ids resource.inbox_ids
json.inboxes resource.inboxes do |inbox|
  json.id inbox.id
  json.name inbox.name
  json.channel_type inbox.channel_type
end
