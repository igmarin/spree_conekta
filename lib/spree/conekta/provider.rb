module Spree::Conekta
  class Provider
    include Spree::Conekta::Client

    attr_accessor :auth_token, :source_method

    attr_reader :options

    PAYMENT_SOURCES = {
        'card' => Spree::Conekta::PaymentSource::Card,
        'banorte' => Spree::Conekta::PaymentSource::Bank,
        'spei' => Spree::Conekta::PaymentSource::Bank,
        'oxxo' => Spree::Conekta::PaymentSource::Cash
    }

    def initialize(options = {})
      @options       = options
      @auth_token    = options[:auth_token]
      @source_method = payment_processor(options[:source_method])
      @order = nil
    end

    def authorize(amount, method_params, gateway_options = {})
      @order = Spree::Order.find_by_number(gateway_options[:order_id].split('-').first)
      discount_total = 0
      if @order.payments.store_credits.valid.any?
        discount_total = @order.payments.store_credits.valid.last.amount * 100
      end
      amount = (@order.amount * 100 - discount_total).to_i
      common = build_common(amount, gateway_options)
      result = commit common, method_params, gateway_options.merge({type: @options[:source_method]})
      @order.create_conekta_charge_details_from_response(result.params["charges"]) if result.success?
      result
    end

    alias_method :purchase, :authorize

    def capture(amount, method_params, gateway_options = {})
      Response.new({}, gateway_options)
    end

    def endpoint
      'charges'
    end

    def payment_processor(source_name)
      PAYMENT_SOURCES[source_name]
    end

    def supports?(brand)
      %w(visa master).include? brand
    end

    def credit(credit_cents, response_code, gateway_options)
      Spree::Conekta::FakeResponse.new
    end

    private

    def commit(common, method_params, gateway_options)
      source_method.request(common, method_params, gateway_options)
      Spree::Conekta::Response.new post(common), source_method
    end

    def build_common(amount, gateway_params)
      if Spree::Conekta.api_version == "2.0.0"
        if source_method == Spree::Conekta::PaymentSource::Cash && gateway_params[:currency] != 'MXN'
          return build_common_to_cash(amount, gateway_params)
        else
          {
            line_items:       line_items(gateway_params, amount),
            id:               gateway_params[:order_id],
            livemode:         !@options[:test_mode],
            object:           "order",
            amount:           amount,
            payment_status:   "pending_payment",
            currency:         gateway_params[:currency],
            shipping_lines:   [shipment(gateway_params)],
            shipping_contact: shipping_contact(gateway_params),
            customer_info:    customer_info(gateway_params),
            created_at:       @order.created_at,
            updated_at:       @order.updated_at,
            charges:          build_charge(amount, gateway_params)
          }
        end
      else
        if source_method == Spree::Conekta::PaymentSource::Cash && gateway_params[:currency] != 'MXN'
          return build_common_to_cash(amount, gateway_params)
        else
          {
            'amount'               => amount,
            'reference_id'         => gateway_params[:order_id],
            'currency'             => gateway_params[:currency],
            'description'          => gateway_params[:order_id],
            'details'              => details(gateway_params)
          }
        end
      end
    end

    def customer_info(gateway_params)
      {
        'object'          => "customer_info",
        'name'            => gateway_params[:billing_address][:name],
        'email'           => gateway_params[:email],
        'phone'           => gateway_params[:billing_address][:phone],
      }
    end

    def details(gateway_params)
      {
        'name'            => gateway_params[:billing_address][:name],
        'email'           => gateway_params[:email],
        'phone'           => gateway_params[:billing_address][:phone],
        'billing_address' => billing_address(gateway_params),
        'line_items'      => line_items(gateway_params, amount),
        'shipment'        => shipment(gateway_params)
      }
    end

    def shipping_address(gateway_params)
      {
        'street1' => gateway_params[:shipping_address][:address1],
        'street2' => gateway_params[:shipping_address][:address2],
        'city'    => gateway_params[:shipping_address][:city],
        'state'   => gateway_params[:shipping_address][:state],
        'country' => gateway_params[:shipping_address][:country],
        'postal_code'     => gateway_params[:shipping_address][:zip]
      }
    end

    def billing_address(gateway_params)
      {
        'email'   => gateway_params[:email],
        'street1' => gateway_params[:billing_address][:address1],
        'street2' => gateway_params[:billing_address][:address2],
        'city'    => gateway_params[:billing_address][:city],
        'state'   => gateway_params[:billing_address][:state],
        'country' => gateway_params[:billing_address][:country],
        'zip'     => gateway_params[:billing_address][:zip]
      }
    end

    def build_charge(amount, gateway_params)
      [{
        object:         "charge",
        livemode:       !@options[:test_mode],
        created_at:     @order.created_at,
        currency:       gateway_params[:currency],
        status:         "pending_payment",
        amount:         amount + gateway_params[:shipping].to_i,
        fee:            gateway_params[:tax],
        customer_id:    "",
        order_id:       "",
        payment_method: options[:source_method] == "oxxo" ?
        oxxo_payment_method(gateway_params) :
        card_payment_method(gateway_params)
      }]
    end

    def oxxo_payment_method(gateway_params)
      {
        service_name:   "OxxoPay",
        object:         "cash_payment",
        type:           "oxxo_cash",
        expires_at:     (@order.created_at + 30.days).to_i,
        store_name:     "OXXO",
        reference:      gateway_params[:order_id]
      }
    end

    def card_payment_method(gateway_params)
      {
        service_name:   "card",
        type:           "card",
      }
    end

    def line_items(gateway_params, amount)
      line_items = @order.line_items.map(&:to_conekta)
      real_total = line_items.inject(0){|sum, item| item[:unit_price]}
      unless amount == real_total
        items_count = @order.line_items.inject(0) {|sum, item| sum += item[:quantity]}
        line_items.each{ |item| item[:unit_price] = ( amount / items_count).ceil.to_i}
      end
      line_items

    end

    def shipment(gateway_params)
      @order = Spree::Order.find_by_number(gateway_params[:order_id].split('-').first)
      shipment = @order.shipments[0]
      carrier = (shipment.present? ? shipment.shipping_method.name : "other")
      traking_id = (shipment.present? ? shipment.tracking : nil)
      {
        :amount       => gateway_params[:shipping].to_i,
        :address      => shipping_address(gateway_params),
        :service      => "other",
        :carrier      => carrier,
        :tracking_id  => traking_id
      }
    end

    def shipping_contact(gateway_params)
      {
        :address      => shipping_address(gateway_params),
      }
    end

    def build_common_to_cash(amount, gateway_params)
      amount_exchanged = Spree::Conekta::Exchange.new(amount, gateway_params[:currency]).amount_exchanged
      {
        'amount' => amount_exchanged,
        'reference_id' => gateway_params[:order_id],
        'currency' => "MXN",
        'description' => gateway_params[:order_id],
        'details' => details(gateway_params)
      }
    end
  end
end
