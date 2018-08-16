module SolidusConekta
  class Engine < ::Rails::Engine
    require 'spree'
    isolate_namespace Spree

    engine_name 'solidus_conekta'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    if Rails.version >= '3.1'
      initializer :assets do |config|
        Rails.application.config.assets.precompile += %w( solidus_conekta.js )
      end
    end

    initializer "spree.conekta.payment_methods", after: "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods << Spree::BillingIntegration::ConektaGateway::Cash
      app.config.spree.payment_methods << Spree::BillingIntegration::ConektaGateway::Card
      app.config.spree.payment_methods << Spree::BillingIntegration::ConektaGateway::Bank
      app.config.spree.payment_methods << Spree::BillingIntegration::ConektaGateway::MonthlyPayment
    end

    initializer 'solidus_conekta.assets.precompile' do |app|
      app.config.assets.precompile += %w( spree/backend/print.css )
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../../app/**/*_decorator*.rb")) do |c|
        Rails.application.config.cache_classes ? require(c) : load(c)
      end
    end

    config.autoload_paths += %W(#{config.root}/lib)
    config.to_prepare &method(:activate).to_proc
  end
end
