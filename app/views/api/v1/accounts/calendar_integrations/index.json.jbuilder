json.array! @integrations do |integration|
  json.partial! 'api/v1/accounts/calendar_integrations/integration', integration: integration
end
