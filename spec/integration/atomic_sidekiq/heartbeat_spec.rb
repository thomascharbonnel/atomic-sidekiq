RSpec.describe AtomicSidekiq::Heartbeat do
  let(:queue) { "default" }
  let(:fetcher) { AtomicSidekiq::AtomicFetch.new(queues: [queue]) }
  let(:work) { Sidekiq.load_json(fetcher.retrieve_work.job) }
  let(:worker) do
    worker = TestJob.new
    worker.jid = work["jid"]
    worker
  end

  def expire_at(jid)
    job = Sidekiq.redis { |conn| conn.get("flight:#{queue}:#{jid}") }
    parsed = Sidekiq.load_json(job)
    parsed["expire_at"]
  end

  def perform_work
    worker.perform(*work["args"])
  end

  before { allow(fetcher).to receive(:sleep) }

  describe "#heartbeat!" do
    let(:time) { Time.now.utc }
    let(:heartbeat) { nil }
    before do
      TestJob.perform_async("heartbeat_timeout" => heartbeat)
      # Force retrieving the work within a known time
      Timecop.freeze(time) { work }
    end

    context "when no timeout is given" do
      it "sets the expiration date to one hour later" do
        new_time = Time.now.utc + 1_800
        Timecop.freeze(new_time) { perform_work }
        expiration_time = new_time + 3_600
        expect(expire_at(worker.jid)).to eq(expiration_time.to_i)
      end
    end

    context "when no timeout is given" do
      let(:heartbeat) { 7_200 }

      it "sets the expiration date to 'timeout' seconds in the future" do
        new_time = Time.now.utc + 1_800
        Timecop.freeze(new_time) { perform_work }
        expiration_time = new_time + 7_200
        expect(expire_at(worker.jid)).to eq(expiration_time.to_i)
      end
    end
  end
end
