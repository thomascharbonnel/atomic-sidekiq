RSpec.describe AtomicSidekiq::UnitOfWork, type: :integration do
  let(:keymaker) { AtomicSidekiq::InFlightKeymaker.new("flight") }

  describe "#acknowledge" do
    let(:jid) { "12345-789-0" }
    let(:job) { { class: "FakeJob", jid: jid, queue: "special" }.to_json }
    let(:inflight_key) { "flight:special:#{jid}" }
    let(:subject) { described_class.new("queue:special", job, in_flight_keymaker: keymaker) }

    before do
      Sidekiq.redis { |conn| conn.set(inflight_key, job) }
    end

    it "deletes the in-flight key for the job" do
      subject.acknowledge
      value = Sidekiq.redis { |conn| conn.get(inflight_key) }
      expect(value).to be_nil
    end
  end

  describe "#requeue" do
    let(:jid) { "12345-789-0" }
    let(:job) { { class: "FakeJob", jid: jid, queue: "special" }.to_json }
    let(:subject) { described_class.new("queue:special", job, in_flight_keymaker: keymaker) }

    context "when the job is in-flight" do
      let(:inflight_key) { "flight:special:#{jid}" }

      before do
        Sidekiq.redis { |conn| conn.set(inflight_key, job) }
      end

      it "adds the job to the queue", only: true do
        subject.requeue
        value = Sidekiq.redis { |conn| conn.lpop("queue:special") }
        expect(value).to eq(job)
      end

      it "removes the in-flight message" do
        subject.requeue
        value = Sidekiq.redis { |conn| conn.get(inflight_key) }
        expect(value).to be_nil
      end
    end

    context "when the job is not in-flight " do
      let(:job) { { class: "FakeJob", jid: jid }.to_json }
      let(:subject) { described_class.new("queue:special", job, in_flight_keymaker: keymaker) }

      it "adds the job to the queue" do
        subject.requeue
        value = Sidekiq.redis { |conn| conn.lpop("queue:special") }
        expect(value).to eq(job)
      end
    end
  end
end
