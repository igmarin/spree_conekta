$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require 'spree_conekta/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'spree_conekta'
  s.version     = SpreeConekta::VERSION
  s.authors     = ['Jonathan Garay', 'Fernando Barajas', 'Manuel Vidaurre', 'Mauricio Murga', 'Erick Alvarez', 'Ismael Marin']
  s.email       = %w(jonathan.garay@crowdint.com fernando.barajas@crowdint.com manuel.vidaurre@agiltec.com.mx mauricio@conekta.io erick@conekta.io ismael.marin@magmalabs.io)
  s.homepage    = 'https://github.com/igmarin/spree_conekta'
  s.summary     = 'Solidus Engine for Conekta Mexican Payment gateway'
  s.description = 'Solidus Engine for Conekta Mexican Payment gateway'

  s.files = Dir['{app,config,models,db,lib}/**/*'] + %w(MIT-LICENSE Rakefile README.md)


  s.add_dependency 'oj', '~> 2.14.0'
  s.add_dependency 'faraday'
  s.add_dependency 'typhoeus'
  s.add_dependency 'faraday_middleware'
  s.add_dependency 'activemerchant'
  s.add_dependency "solidus", "~> 1.3"
  s.add_dependency 'coffee-rails'
  s.add_dependency 'celluloid'
end
