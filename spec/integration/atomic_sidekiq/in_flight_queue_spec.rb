RSpec.describe AtomicSidekiq::InFlightQueue, type: :integration do
  subject { described_class.new }

  describe "#list" do
    context "when there are no inflight jobs" do
      it "returns an empty array" do
        expect(subject.list).to eq([])
      end
    end

    context "when there are inflight jobs enqueued" do
      let(:jid) { "12345-789-23456" }
      let(:expire_at) { Time.now.to_i + 60_000 }
      let(:job) { { class: "FakeJob", queue: "special", jid: jid, expire_at: expire_at }.to_json }
      let(:inflight_key) { "flight:special:#{jid}" }

      before do
        Sidekiq.redis { |conn| conn.set(inflight_key, job) }
      end

      it "returns an array with the jobs inflight" do
        result = subject.list

        expect(result).to match([a_hash_including(JSON.parse(job))])
      end
    end
  end

  describe "#delete_job" do
    let(:jid) { "12345-789-23456" }

    context "when the job exists" do
      let(:expire_at) { Time.now.to_i + 60_000 }
      let(:job) { { class: "FakeJob", queue: "special", jid: jid, expire_at: expire_at }.to_json }
      let(:inflight_key) { "flight:special:#{jid}" }

      before do
        Sidekiq.redis { |conn| conn.set(inflight_key, job) }
      end

      it "deletes the job" do
        subject.delete_job(jid)

        msg = Sidekiq.redis { |conn| conn.get(inflight_key) }
        expect(msg).to be_nil
      end

      it "returns the number of jobs that matched the job matcher" do
        result = subject.delete_job(jid)

        expect(result).to eq(1)
      end
    end

    context "when the job does not exists" do
      it "returns 0" do
        result = subject.delete_job(jid)

        expect(result).to eq(0)
      end
    end
  end
end
