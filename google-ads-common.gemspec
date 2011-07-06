# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'ads_common/api_config'

GEM_NAME = 'google-ads-common'
docs = ['README', 'COPYING', 'ChangeLog']

Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = GEM_NAME
  s.version = AdsCommon::ApiConfig::ADS_COMMON_VERSION
  s.summary = 'Common code for Google Ads APIs.'
  s.description = ("%s provides essential utilities shared by all Ads Ruby " +
      "client libraries.") % GEM_NAME
  s.authors = ['Sergio Gomes', 'Danial Klimkin']
  s.email = 'api.dklimkin@gmail.com'
  s.homepage = 'http://code.google.com/p/google-api-ads-ruby/'
  s.require_path = 'lib'
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.has_rdoc = true
  s.extra_rdoc_files = docs
  s.add_dependency('savon', '~> 0.9.1')
  s.add_dependency('soap4r', '= 1.5.8')
  s.add_dependency('httpclient', '>= 2.1.6')
  s.add_dependency('httpi', '~> 0.9.2')
  s.add_dependency('oauth', '~> 0.4.5')
end

