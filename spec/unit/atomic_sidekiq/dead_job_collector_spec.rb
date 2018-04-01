RSpec.describe AtomicSidekiq::DeadJobCollector do
  describe ".new" do
    it "initializes an instance of DeadJobCollector" do
      obj = described_class.new("queue:special")
      expect(obj).to be_an_instance_of(AtomicSidekiq::DeadJobCollector)
    end
  end

  describe ".collect!" do
    let(:queues) { ["queue:default", "queue:special"] }
    let(:collector) { instance_double("AtomicSidekiq::DeadJobCollector", collect!: nil) }

    before do
      allow(described_class).to receive(:new).and_return(collector)
    end

    it "initializes the collector for each queue" do
      described_class.collect!(queues)
      expect(described_class).to have_received(:new).twice
    end

    it "collects the dead jobs for queue:default" do
      default_collector = instance_double("AtomicSidekiq::DeadJobCollector", collect!: nil)
      allow(described_class).to receive(:new).with("queue:default").and_return(default_collector)
      described_class.collect!(queues)
      expect(default_collector).to have_received(:collect!).once
    end

    it "collects the dead jobs for queue:special" do
      special_collector = instance_double("AtomicSidekiq::DeadJobCollector", collect!: nil)
      allow(described_class).to receive(:new).with("queue:special").and_return(special_collector)
      described_class.collect!(queues)
      expect(special_collector).to have_received(:collect!).once
    end
  end
end
