require "sidekiq/web"
require_relative "lib/atomic-sidekiq"

Sidekiq.configure_client do |config|
  config.redis = { db: 13 }
end

map "/sidekiq" do
  run Sidekiq::Web
end
