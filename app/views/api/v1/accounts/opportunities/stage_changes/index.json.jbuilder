json.array! @stage_changes do |change|
  json.id change.id
  json.opportunity_id change.opportunity_id
  json.from_value change.from_value.to_f
  json.to_value change.to_value.to_f
  json.notes change.notes
  json.created_at change.created_at
  json.value_changed change.value_changed?
  json.value_difference change.value_difference.to_f

  if change.user.present?
    json.user do
      json.id change.user.id
      json.name change.user.name
      json.thumbnail change.user.avatar_url
    end
  end

  if change.from_stage.present?
    json.from_stage do
      json.id change.from_stage.id
      json.name change.from_stage.name
      json.color change.from_stage.color
    end
  end

  if change.to_stage.present?
    json.to_stage do
      json.id change.to_stage.id
      json.name change.to_stage.name
      json.color change.to_stage.color
    end
  end
end
