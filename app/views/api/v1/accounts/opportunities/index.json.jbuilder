json.payload do
  json.array! @opportunities do |opportunity|
    json.partial! 'api/v1/accounts/opportunities/opportunity', resource: opportunity
  end
end

json.meta do
  json.count @opportunities_count
  json.current_page @opportunities.current_page
  json.total_pages @opportunities.total_pages
end
