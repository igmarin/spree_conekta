Spree::LineItem.class_eval do
  def to_conekta
    {
      :name        => variant.name,
      :description => variant.description,
      :sku         => variant.sku,
      :unit_price  => ((variant.price + adjustment_total).to_f * 100).to_i,
      :quantity    => quantity
    }
  end
end
