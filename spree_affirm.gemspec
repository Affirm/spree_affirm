# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)
require "spree_affirm/version"

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_affirm'
  s.version     = SpreeAffirm::VERSION
  s.summary     = 'Affirm Spree Payment Gateway'
  s.description = 'Affirm payment Gateway for Spree'
  s.required_ruby_version = '>= 3.0.3'

  s.author    = 'Affirm'
  s.email     = 'mts@affirm.com'
  s.homepage  = 'http://www.affirm.com'

  s.files       = Dir['README.md', 'lib/**/*', 'spree_affirm.gemspec']
  s.require_paths = ['lib']
  s.requirements << 'none'

  s.add_dependency 'spree_core', '>= 4.4.0'

  s.add_development_dependency 'factory_girl', '~> 4.2'
  s.add_development_dependency 'ffaker', '~> 1.16'
  s.add_development_dependency 'rspec-rails',  '~> 2.13'
  s.add_development_dependency 'simplecov', '~> 0.9'
  s.add_development_dependency 'simplecov-rcov', '~> 0.2'
  s.add_development_dependency 'sqlite3', '~> 1.3'
end