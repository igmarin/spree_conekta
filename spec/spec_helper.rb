ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../dummy/config/environment.rb',  __FILE__)

require 'solidus_frontend'
require 'rspec/rails'
require 'capybara/poltergeist'
require 'rails-controller-testing'
require 'oj'

Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |file| require file }

require 'spree/testing_support/url_helpers'
require 'spree/testing_support/controller_requests'
require 'spree/testing_support/authorization_helpers'
require 'spree/testing_support/factories/zone_factory'
require 'spree/testing_support/preferences'
require 'spree/testing_support/factories'

require 'spree/api/testing_support/helpers'
require 'spree/api/testing_support/setup'
require 'vcr'

VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = true
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.ignore_localhost = true
  config.configure_rspec_metadata!
  config.default_cassette_options = { decode_compressed_response: true }
end

Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

RSpec.configure do |config|
  config.infer_base_class_for_anonymous_controllers = false
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = true

  config.include Spree::Api::TestingSupport::Helpers, type: :controller
  config.extend  Spree::Api::TestingSupport::Setup, type: :controller
  config.include Spree::TestingSupport::ControllerRequests, type: :controller
  config.include Spree::TestingSupport::UrlHelpers
  config.extend Spree::TestingSupport::AuthorizationHelpers::Request, type: :request
  config.include Spree::TestingSupport::Preferences, type: :controller
  config.include Spree::TestingSupport::Preferences, type: :model
end
