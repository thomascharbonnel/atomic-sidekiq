RSpec.describe Sidekiq::Worker do
  describe "#heartbeat!" do
    context "when no time is given" do
      Sidekiq::Testing.inline! do
        TestJob.perform_async("example")
      end
    end
  end
end
