# coding: utf-8
$:.push File.expand_path('../lib', __FILE__)
require 'omniauth-mvc/version'

Gem::Specification.new do |s|
  s.name          = "omniauth-mvc"
  s.version       = OmniAuth::MVC::VERSION
  s.authors       = ["Yasuhiro Manai"]
  s.email         = ["yasuhiro.manai@gmail.com"]
  s.summary       = %q{MVC-online OAuth2 Strategy for OmniAuth}
  s.description   = s.summary
  s.homepage      = "https://github.com/yasu/omniauth-mvc"
  s.license       = "MIT"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'omniauth', '~> 1.2'
  s.add_runtime_dependency 'omniauth-oauth2', '~> 1.4'

  s.add_development_dependency "bundler", "~> 1.10"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "rs"
end