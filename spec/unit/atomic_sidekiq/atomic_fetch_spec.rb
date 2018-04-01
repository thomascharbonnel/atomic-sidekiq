RSpec.describe AtomicSidekiq::AtomicFetch do
  before { AtomicSidekiq::AtomicFetch.class_variable_set(:@@next_collection, nil) }

  describe ".new" do
    it "initializes an instance of AtomicFetch" do
      obj = described_class.new(queues: [])
      expect(obj).to be_instance_of(AtomicSidekiq::AtomicFetch)
    end

    it "initializes an instance of AtomicOperation::Retrieve with the default prefix" do
      allow(AtomicSidekiq::AtomicOperation::Retrieve).to receive(:new)
      described_class.new(queues: [])
      expect(AtomicSidekiq::AtomicOperation::Retrieve).to have_received(:new).with(in_flight_prefix: "flight:")
    end
  end

  describe "#retrieve_work" do
    let(:retrieve_op) { instance_double("AtomicSidekiq::AtomicOperation::Retrieve", perform: nil) }
    before do
      allow(AtomicSidekiq::AtomicOperation::Retrieve).to receive(:new)
        .with(in_flight_prefix: "flight:")
        .and_return(retrieve_op)
      allow(subject).to receive(:sleep)
      allow(AtomicSidekiq::DeadJobCollector).to receive(:collect!)
    end

    context "when no value is retrieved" do
      let(:poll_interval) { nil }
      subject do
        described_class.new(
          queues: %w[default special],
          atomic_fetch: { poll_interval: poll_interval }
        )
      end

      it "returns nil" do
        expect(subject.retrieve_work).to be_nil
      end

      context "when no polling interval is set" do
        it "waits 5 seconds before resuming" do
          subject.retrieve_work
          expect(subject).to have_received(:sleep).with(5)
        end
      end

      context "when a polling interval value is given" do
        let(:poll_interval) { 10 }

        it "waits the given time before resuming" do
          subject.retrieve_work
          expect(subject).to have_received(:sleep).with(10)
        end
      end
    end

    context "when a value is retrieved" do
      subject { described_class.new(queues: %w[default special]) }
      let(:unit_of_work) { instance_double("AtomicSidekiq::UnitOfWork") }

      before do
        allow(retrieve_op).to receive(:perform).and_return("work")
      end

      it "retrieves a UnitOfWork with the retrieved work" do
        allow(AtomicSidekiq::UnitOfWork).to receive(:new).with("work").and_return(unit_of_work)
        work = subject.retrieve_work
        expect(work).to eq(unit_of_work)
      end

      it "does not call throttles the call" do
        allow(AtomicSidekiq::UnitOfWork).to receive(:new)
        subject.retrieve_work
        expect(subject).not_to have_received(:sleep)
      end
    end

    context "when no expiration time is given" do
      subject do
        described_class.new(queues: %w[default special], atomic_fetch: { expiration_time: nil })
      end

      it "calls the retrieve operation with the default time" do
        time = Time.now.utc
        Timecop.freeze(time) { subject.retrieve_work }
        expect(retrieve_op).to have_received(:perform).with(anything, time.to_i + 3600)
      end
    end

    context "when an expiration time is given" do
      subject do
        described_class.new(queues: %w[default special], atomic_fetch: { expiration_time: 100 })
      end

      it "calls the retrieve operation with the given time" do
        time = Time.now.utc
        Timecop.freeze(time) { subject.retrieve_work }
        expect(retrieve_op).to have_received(:perform).with(anything, time.to_i + 100)
      end
    end

    context "when no queue order is set" do
      subject { described_class.new(queues: []) }

      it "calls the retrieve operation with all queues in random order" do
        allow_any_instance_of(Array).to receive(:shuffle).and_return(["queue:special", "queue:default"])
        subject.retrieve_work
        expect(retrieve_op).to have_received(:perform).with(["queue:special", "queue:default"], anything)
      end

      it "runs the DeadJobCollector on all queues in a random order" do
        allow_any_instance_of(Array).to receive(:shuffle).and_return(["queue:special", "queue:default"])
        Timecop.freeze(Time.now + 1) { subject.retrieve_work }
        expect(AtomicSidekiq::DeadJobCollector).to have_received(:collect!).with(["queue:special", "queue:default"])
      end
    end

    context "when queue order is set to strict" do
      subject { described_class.new(queues: %w[default special], strict: true) }

      it "calls the retrieve operation with all queues in the given order" do
        subject.retrieve_work
        expect(retrieve_op).to have_received(:perform).with(["queue:default", "queue:special"], anything)
      end
    end
  end
end
