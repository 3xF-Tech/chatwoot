json.id resource.id
json.display_id resource.display_id
json.name resource.name
json.description resource.description
json.value resource.value.to_f
json.currency resource.currency
json.probability resource.probability
json.expected_close_date resource.expected_close_date
json.actual_close_date resource.actual_close_date
json.status resource.status
json.lost_reason resource.lost_reason
json.source resource.source
json.custom_attributes resource.custom_attributes
json.stage_entered_at resource.stage_entered_at
json.last_activity_at resource.last_activity_at
json.created_at resource.created_at
json.updated_at resource.updated_at

json.pipeline_id resource.pipeline_id
json.pipeline_stage_id resource.pipeline_stage_id
json.contact_id resource.contact_id
json.company_id resource.company_id
json.owner_id resource.owner_id
json.team_id resource.team_id

json.weighted_value resource.weighted_value
json.items_total resource.items_total

if resource.pipeline.present?
  json.pipeline do
    json.id resource.pipeline.id
    json.name resource.pipeline.name
  end
end

if resource.pipeline_stage.present?
  json.pipeline_stage do
    json.id resource.pipeline_stage.id
    json.name resource.pipeline_stage.name
    json.probability resource.pipeline_stage.probability
    json.stage_type resource.pipeline_stage.stage_type
    json.color resource.pipeline_stage.color
  end
end

if resource.contact.present?
  json.contact do
    json.id resource.contact.id
    json.name resource.contact.name
    json.email resource.contact.email
    json.phone_number resource.contact.phone_number
    json.thumbnail resource.contact.avatar_url
  end
end

if resource.company.present?
  json.company do
    json.id resource.company.id
    json.name resource.company.name
    json.domain resource.company.domain
  end
end

if resource.owner.present?
  json.owner do
    json.id resource.owner.id
    json.name resource.owner.name
    json.email resource.owner.email
    json.thumbnail resource.owner.avatar_url
  end
end

if resource.team.present?
  json.team do
    json.id resource.team.id
    json.name resource.team.name
  end
end
