module Spree
  class BillingIntegration::ConektaGateway::Bank < Spree::PaymentMethod
    preference :auth_token, :string
    preference :source_method, :string, default: 'banorte'

    unless Rails::VERSION::MAJOR >= 4
      attr_accessible :preferred_auth_token, :preferred_source_method, :gateway_response
    end

    if SolidusSupport.solidus_gem_version < Gem::Version.new('2.3.x')
      def provider_class
       Spree::Conekta::Provider
      end

      def method_type
        'conekta'
      end
    else
      def gateway_class
       Spree::Conekta::Provider
      end

      def partial_name
        'conekta'
      end
    end

    def payment_source_class
      Spree::ConektaPayment
    end

    def card?
      false
    end

    def auto_capture?
      false
    end
  end
end
