class TestJob
  include Sidekiq::Worker

  def perform(str)
  end
end
