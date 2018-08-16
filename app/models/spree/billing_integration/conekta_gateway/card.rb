module Spree
  class BillingIntegration::ConektaGateway::Card < PaymentMethod::CreditCard
    preference :auth_token, :string
    preference :public_auth_token, :string
    preference :source_method, :string, default: 'card'

    unless Rails::VERSION::MAJOR >= 4
      attr_accessible :preferred_auth_token, :preferred_public_auth_token, :preferred_source_method, :gateway_response
    end

    if SolidusSupport.solidus_gem_version < Gem::Version.new('2.3.x')
      def provider_class
       Spree::Conekta::Provider
      end

      def method_type
        'conekta_card'
      end
    else
      def gateway_class
        Spree::Conekta::Provider
      end

      def partial_name
        'conekta_card'
      end
    end

    def payment_source_class
      CreditCard
    end

    def card?
      true
    end

    def auto_capture?
      true
    end

    def with_installments?
      false
    end
  end
end
