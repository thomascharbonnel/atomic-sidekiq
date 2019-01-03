# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name          = "atomic-sidekiq"
  s.version       = "0.0.0"
  s.date          = "2001-01-01"
  s.summary       = "Reliable fetcher for Sidekiq"
  s.description   = "Reliable fetcher for Sidekiq"
  s.homepage      = "https://github.com/Colex/atomic-sidekiq"
  s.authors       = ["Alex Correia Santos"]
  s.email         = ["alex.santios@visiblealpha.com"]
  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec)/}) }
  s.require_paths = ["lib"]
  s.license       = "MIT"

  s.required_ruby_version = ">= 2.2"

  s.add_development_dependency "bundler", "~> 1.12"
  s.add_development_dependency "rake", "~> 11.3"
  s.add_development_dependency "rspec", "~> 3.6"
  s.add_development_dependency "rubocop", "~> 0.54"
  s.add_development_dependency "timecop", "~> 0.9"
  s.add_development_dependency "codecov", ">= 0.1.10"
  s.add_development_dependency "thin"
  s.add_development_dependency "capybara", "~> 3.1.1"
  s.add_development_dependency "xpath", "~> 3.1.0"
  s.add_development_dependency "selenium-webdriver"

  s.add_runtime_dependency "sidekiq", "~> 5.0"
end
