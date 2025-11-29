json.id activity.id
json.opportunity_id activity.opportunity_id
json.user_id activity.user_id
json.activity_type activity.activity_type
json.title activity.title
json.description activity.description
json.scheduled_at activity.scheduled_at
json.completed_at activity.completed_at
json.is_done activity.is_done
json.reminder_at activity.reminder_at
json.duration_minutes activity.duration_minutes
json.metadata activity.metadata
json.created_at activity.created_at
json.updated_at activity.updated_at
json.overdue activity.overdue?
json.due_today activity.due_today?

if activity.user.present?
  json.user do
    json.id activity.user.id
    json.name activity.user.name
    json.email activity.user.email
    json.thumbnail activity.user.avatar_url
  end
end
