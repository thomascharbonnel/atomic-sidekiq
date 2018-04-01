RSpec.describe AtomicSidekiq::AtomicFetch do
  describe ".new" do
    it "initializes an instance of AtomicFetch" do
      obj = described_class.new({ queues: [] })
      expect(obj).to be_instance_of(AtomicSidekiq::AtomicFetch)
    end
  end
end
