describe AtomicSidekiq::UnitOfWork do
  describe ".new" do
    it "initializes an instance of UnitOfWork" do
      obj = described_class.new
      expect(obj).to be_instance_of(AtomicSidekiq::UnitOfWork)
    end
  end

  describe "#queue_name" do
    context "when a 'queue:' prefix is present" do
      it "returns the name of the queue unchanged" do
        obj = described_class.new("queue:foobar")
        expect(obj.queue_name).to eq("queue:foobar")
      end
    end

    context "when no prefix is present" do
      it "returns the name of the queue with a queue: prefix" do
        obj = described_class.new("foobar")
        expect(obj.queue_name).to eq("queue:foobar")
      end
    end

    context "when prefix contains queue:" do
      it "returns only queue: as the prefix" do
        obj = described_class.new("super:queue:foobar")
        expect(obj.queue_name).to eq("queue:foobar")
      end
    end
  end
end
