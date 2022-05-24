# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)
require "spree_affirm/version"

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_affirm'
  s.version     = SpreeAffirm::VERSION
  s.summary     = 'Affirm Spree Payment Gateway'
  s.description = 'Affirm payment Gateway for Spree'
  s.required_ruby_version = '>= 1.9.3'

  s.author    = 'Affirm'
  s.email     = 'mts@affirm.com'
  s.homepage  = 'http://www.affirm.com'

  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '>= 2.2.0'

  s.add_development_dependency 'factory_girl', '~> 4.2'
  s.add_development_dependency 'ffaker', '~> 1.16'
  s.add_development_dependency 'rspec-rails',  '~> 2.13'
  s.add_development_dependency 'simplecov', '~> 0.9'
  s.add_development_dependency 'simplecov-rcov', '~> 0.2'
  s.add_development_dependency 'sqlite3', '~> 1.3'
end
