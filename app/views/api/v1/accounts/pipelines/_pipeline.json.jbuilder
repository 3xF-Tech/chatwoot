json.id resource.id
json.name resource.name
json.description resource.description
json.is_default resource.is_default
json.settings resource.settings
json.created_at resource.created_at
json.updated_at resource.updated_at

if local_assigns[:include_stages] != false
  json.stages resource.stages.ordered do |stage|
    json.partial! 'api/v1/accounts/pipelines/stages/stage', stage: stage
  end
end
