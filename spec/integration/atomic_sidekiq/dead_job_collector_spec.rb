RSpec.describe AtomicSidekiq::DeadJobCollector, type: :integration do
  let(:keymaker) { AtomicSidekiq::InFlightKeymaker.new("flight") }

  describe "#collect!" do
    context "when there are no expired jobs" do
      let(:jid) { "12345-789-23456" }
      let(:expire_at) { Time.now.to_i + 60_000 }
      let(:job) { { class: "FakeJob", queue: "special", jid: jid, expire_at: expire_at }.to_json }
      let(:inflight_key) { "flight:special:#{jid}" }
      let(:collector) { described_class.new("queue:special", in_flight_keymaker: keymaker) }

      before do
        Sidekiq.redis { |conn| conn.set(inflight_key, job) }
      end

      it "does not remove any of the jobs in-flight" do
        collector.collect!

        msg = Sidekiq.redis { |conn| conn.get(inflight_key) }
        expect(msg).to eq(job)
      end

      it "does not add any jobs to the queue" do
        collector.collect!

        len = Sidekiq.redis { |conn| conn.llen("queue:special") }
        expect(len).to eq(0)
      end
    end

    context "when there are expired jobs in a different queue" do
      let(:jid) { "12345-789-23456" }
      let(:expire_at) { Time.now.to_i - 60_000 }
      let(:job) { { class: "FakeJob", queue: "special", jid: jid, expire_at: expire_at }.to_json }
      let(:inflight_key) { "flight:special:#{jid}" }
      let(:collector) { described_class.new("default", in_flight_keymaker: keymaker) }

      before do
        Sidekiq.redis { |conn| conn.set(inflight_key, job) }
      end

      it "does not remove any of the jobs in-flight" do
        collector.collect!

        msg = Sidekiq.redis { |conn| conn.get(inflight_key) }
        expect(msg).to eq(job)
      end

      it "does not add any jobs to the queue" do
        collector.collect!

        len = Sidekiq.redis { |conn| conn.llen("queue:default") }
        expect(len).to eq(0)
      end
    end

    context "when there are expired jobs" do
      let(:jid) { "12345-789-23456" }
      let(:expire_at) { Time.now.to_i - 60_000 }
      let(:job) { { class: "FakeJob", queue: "special", jid: jid, expire_at: expire_at }.to_json }
      let(:inflight_key) { "flight:special:#{jid}" }
      let(:collector) { described_class.new("queue:special", in_flight_keymaker: keymaker) }

      before do
        Sidekiq.redis { |conn| conn.set(inflight_key, job) }
      end

      it "removes the expired jobs from in-flight" do
        collector.collect!

        msg = Sidekiq.redis { |conn| conn.get(inflight_key) }
        expect(msg).to be_nil
      end

      it "adds all expired jobs to the end of the queue without the 'expire_at' timestamp" do
        collector.collect!

        msg = Sidekiq.redis { |conn| conn.lpop("queue:special") }
        expect(msg).to eq({
          class: "FakeJob",
          queue: "special",
          jid: "12345-789-23456"
        }.to_json)
      end
    end

    context "when collector is called with skip_recovery set to true" do
      let(:jid) { "12345-789-23456" }
      let(:expire_at) { Time.now.to_i - 60_000 }
      let(:job) { { class: "FakeJob", queue: "cron", jid: jid, expire_at: expire_at }.to_json }
      let(:inflight_key) { "flight:cron:#{jid}" }
      let(:collector) do
        described_class.new(
          "queue:cron",
          in_flight_keymaker: keymaker
        )
      end

      before do
        Sidekiq.redis { |conn| conn.set(inflight_key, job) }
      end

      it "removes the expired jobs from in-flight" do
        collector.collect!(skip_recovery: true)

        msg = Sidekiq.redis { |conn| conn.get(inflight_key) }
        expect(msg).to be_nil
      end

      it "does not add expired job to the end of the queue" do
        collector.collect!(skip_recovery: true)

        msg = Sidekiq.redis { |conn| conn.lpop("queue:cron") }
        expect(msg).to be_nil
      end
    end
  end
end
