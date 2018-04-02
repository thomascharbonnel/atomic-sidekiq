RSpec.describe AtomicSidekiq::AtomicOperation::Base do
  describe ".new" do
    it "initializes an instance of AtomicOperation::Base" do
      obj = described_class.new(in_flight_keymaker: nil)
      expect(obj).to be_an_instance_of(AtomicSidekiq::AtomicOperation::Base)
    end
  end
end
