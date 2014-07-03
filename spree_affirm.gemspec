# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)
require "spree_affirm/version"

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_affirm'
  s.version     = SpreeAffirm::VERSION
  s.summary     = 'Affirm Spree Payment Gateway'
  s.description = 'Affirm payment Gateway for spree'
  s.required_ruby_version = '>= 1.9.3'

  s.author    = 'Yu Pan'
  s.email     = 'yu.pan@affirm.com'
  s.homepage  = 'http://www.spreecommerce.com'

  # s.files       = `git ls-files`.split("\n")
  # s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '~> 2.2.0'

  s.add_development_dependency 'capybara', '~> 2.1'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl', '~> 4.2'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'gem-release'
  s.add_development_dependency 'rspec-rails',  '~> 2.13'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'simplecov-rcov'
  s.add_development_dependency 'sqlite3'
end
