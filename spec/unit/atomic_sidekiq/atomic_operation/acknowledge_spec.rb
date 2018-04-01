RSpec.describe AtomicSidekiq::AtomicOperation::Acknowledge do
  describe ".new" do
    it "initializes an instance of AtomicOperation::Acknowledge" do
      obj = described_class.new(in_flight_prefix: "FLIGHT:")
      expect(obj).to be_an_instance_of(AtomicSidekiq::AtomicOperation::Acknowledge)
    end
  end
end
