json.description('Spree Order')
json.amount(@order.display_total.cents)
json.currency(Spree::Config[:currency])
json.reference_id(@order.number)

json.details do
  json.name(@order.name)
  json.phone(@order.bill_address.phone)
  json.email(@order.email)

  json.billing_address do
    json.email(@order.email)
    json.street1(@order.bill_address.address1)
    json.street2(@order.bill_address.address2)
    json.city(@order.bill_address.city)
    json.state(@order.bill_address.state)
    json.country(@order.bill_address.country)
    json.zip(@order.bill_address.zipcode)

    json.line_items(@order.line_items.map(&:to_conekta))

    json.shipment do
      json.price(@order.shipments.sum(:cost))
      json.address do
        json.street1(@order.ship_address.address1)
        json.street2(@order.ship_address.address2)
        json.city(@order.ship_address.city)
        json.state(@order.ship_address.state)
        json.country(@order.ship_address.country)
        json.zip(@order.ship_address.zipcode)
      end
    end
  end
end
