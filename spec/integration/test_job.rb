class TestJob
  include Sidekiq::Worker
  include AtomicSidekiq::Heartbeat

  def perform(opts = {})
    heartbeat!(opts["heartbeat_timeout"])
  end
end
