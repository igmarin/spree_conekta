source "http://rubygems.org"
gem 'solidus', '~> 1.3.0'
gem 'sass-rails', '~> 5.0'

# Spree Internationalization https://github.com/spree/spree_i18n
gem 'solidus_i18n', github: 'solidusio-contrib/solidus_i18n', branch: 'master'
gem 'globalize', github: 'globalize/globalize', branch: 'master'

group :test, :development do
  gem 'rspec-rails', '~> 3.1.0'
  gem 'sqlite3'
  gem 'factory_girl'
  gem 'pry'
  gem 'database_cleaner'
  gem 'spork'
  gem 'poltergeist'
  gem 'selenium-webdriver'
  gem 'capybara-webkit'
  gem 'capybara'
  gem 'vcr'
end

group :test do
  gem 'ffaker', '2.0'
end


gemspec
