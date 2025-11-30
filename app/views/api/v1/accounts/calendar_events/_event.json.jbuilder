json.id event.id
json.title event.title
json.description event.description
json.start_time event.starts_at
json.end_time event.ends_at
json.all_day event.all_day
json.location event.location
json.video_conference_link event.meeting_url
json.event_type event.event_type
json.status event.status
json.visibility event.visibility
json.recurrence_rule event.recurrence_rule
json.reminder_minutes event.reminders&.first&.dig('minutes')
json.color event.metadata&.dig('color') || 'blue'
json.external_id event.external_id
json.metadata event.metadata
json.sync_status event.sync_status
json.user_id event.user_id
json.calendar_integration_id event.calendar_integration_id
json.created_at event.created_at
json.updated_at event.updated_at

json.attendees event.attendees do |attendee|
  json.id attendee.id
  json.email attendee.email
  json.response_status attendee.response_status
  json.required attendee.required
  json.contact_id attendee.contact_id
  json.user_id attendee.user_id

  if attendee.contact
    json.contact do
      json.id attendee.contact.id
      json.name attendee.contact.name
      json.email attendee.contact.email
      json.avatar_url attendee.contact.avatar_url
    end
  end

  if attendee.user
    json.user do
      json.id attendee.user.id
      json.name attendee.user.name
      json.email attendee.user.email
      json.avatar_url attendee.user.avatar_url
    end
  end
end

json.links event.event_links do |link|
  json.id link.id
  json.linkable_type link.linkable_type
  json.linkable_id link.linkable_id

  case link.linkable_type
  when 'Opportunity'
    if link.linkable
      json.linkable do
        json.id link.linkable.id
        json.name link.linkable.name
        json.stage link.linkable.pipeline_stage&.name
      end
    end
  when 'Contact'
    if link.linkable
      json.linkable do
        json.id link.linkable.id
        json.name link.linkable.name
        json.email link.linkable.email
      end
    end
  when 'Company'
    if link.linkable
      json.linkable do
        json.id link.linkable.id
        json.name link.linkable.name
      end
    end
  when 'Conversation'
    if link.linkable
      json.linkable do
        json.id link.linkable.id
        json.display_id link.linkable.display_id
      end
    end
  end
end

if event.calendar_integration
  json.integration do
    json.id event.calendar_integration.id
    json.provider event.calendar_integration.provider
    json.provider_email event.calendar_integration.provider_email
  end
end
