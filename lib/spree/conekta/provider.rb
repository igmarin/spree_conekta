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
    end

    def authorize(amount, method_params, gateway_options = {})
      common = build_common(amount, gateway_options)
      commit common, method_params, gateway_options.merge({type: @options[:source_method]})
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
        'line_items'      => line_items(gateway_params),
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

    def line_items(gateway_params)
      order = Spree::Order.find_by_number(gateway_params[:order_id].split('-').first)
      order.line_items.map(&:to_conekta)
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
