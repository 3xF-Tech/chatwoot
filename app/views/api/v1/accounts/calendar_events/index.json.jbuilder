json.array! @events do |event|
  json.partial! 'api/v1/accounts/calendar_events/event', event: event
end
