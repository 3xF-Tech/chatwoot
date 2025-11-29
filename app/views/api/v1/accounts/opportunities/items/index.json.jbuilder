json.array! @items do |item|
  json.partial! 'api/v1/accounts/opportunities/items/item', item: item
end
