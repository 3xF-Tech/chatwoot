json.array! @stages do |stage|
  json.partial! 'api/v1/accounts/pipelines/stages/stage', stage: stage
end
