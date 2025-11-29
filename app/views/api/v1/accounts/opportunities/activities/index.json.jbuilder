json.array! @activities do |activity|
  json.partial! 'api/v1/accounts/opportunities/activities/activity', activity: activity
end
