RSpec.describe AtomicSidekiq::AtomicFetch, type: :integration do
  describe "#retrieve_work" do
    context "when there is only one queue" do
      subject { described_class.new(queues: ["default"], atomic_fetch: { poll_interval: 0 }) }

      context "when there are no jobs enqueued" do
        it "returns nil" do
          expect(subject.retrieve_work).to be_nil
        end
      end

      context "when there's a job enqueued" do
        let(:time) { Time.now.utc }
        let!(:jid) do
          Timecop.freeze(time) { TestJob.perform_async("test") }
        end

        it "returns a unit of work" do
          expect(subject.retrieve_work).to be_an_instance_of(AtomicSidekiq::UnitOfWork)
        end

        it "returns unit of work with used queue name" do
          work = subject.retrieve_work
          expect(work.queue_name).to eq("queue:default")
        end

        it "returns unit of work with popped job data" do
          work = subject.retrieve_work
          job = JSON.parse(work.job)
          expect(job).to eq(
            "class"       => "TestJob",
            "args"        => ["test"],
            "retry"       => true,
            "queue"       => "default",
            "jid"         => jid,
            "created_at"  => time.to_f,
            "enqueued_at" => time.to_f,
            "expire_at"   => time.to_i + AtomicSidekiq::AtomicFetch::DEFAULT_EXPIRATION_TIME
          )
        end

        it "creates an entry as an in-flight message" do
          in_flight_key = "#{AtomicSidekiq::AtomicFetch::IN_FLIGHT_KEY_PREFIX}:default:#{jid}"

          subject.retrieve_work

          value = Sidekiq.redis { |conn| conn.get(in_flight_key) }
          expect(value).not_to be_nil
        end

        it "stores job data in the in-flight key" do
          in_flight_key = "#{AtomicSidekiq::AtomicFetch::IN_FLIGHT_KEY_PREFIX}:default:#{jid}"

          job = subject.retrieve_work.job

          value = Sidekiq.redis { |conn| conn.get(in_flight_key) }
          expect(value).to eq(job)
        end
      end
    end

    context "when there are multiple queues" do
      let(:queues) { %w[default special] }

      context "when queue priority is not strict" do
        subject { described_class.new(queues: queues, atomic_fetch: { poll_interval: 0 }) }

        context "when there are no jobs enqueued in any of the queues" do
          it "returns nil" do
            expect(subject.retrieve_work).to be_nil
          end
        end

        context "when there is a job enqueued only in the second queue" do
          let(:time) { Time.now }
          let!(:jid) do
            Timecop.freeze(time) { TestJob.set(queue: "special").perform_async("test") }
          end

          it "returns a unit of work" do
            work = subject.retrieve_work
            expect(work).to be_an_instance_of(AtomicSidekiq::UnitOfWork)
          end

          it "returns unit of work from the special queue" do
            work = subject.retrieve_work
            expect(work.queue_name).to eq("queue:special")
          end
        end

        context "when there is a job enqueued in both queues" do
          let(:time) { Time.now }
          let!(:jid_special) do
            Timecop.freeze(time) { TestJob.set(queue: "special").perform_async("test") }
          end
          let!(:jid_default) do
            Timecop.freeze(time) { TestJob.set(queue: "default").perform_async("test2") }
          end

          it "returns a unit of work" do
            work = subject.retrieve_work
            expect(work).to be_an_instance_of(AtomicSidekiq::UnitOfWork)
          end

          it "returns unit of work from random queue" do
            allow_any_instance_of(Array).to receive(:shuffle).and_return(["queue:special", "queue:default"])
            work = subject.retrieve_work
            expect(work.queue_name).to eq("queue:special")
          end
        end
      end

      context "when queue priority is strict" do
        subject { described_class.new(queues: queues, strict: true, atomic_fetch: { poll_interval: 0 }) }

        context "when there are no jobs enqueued in any of the queues" do
          it "returns nil" do
            expect(subject.retrieve_work).to be_nil
          end
        end

        context "when there is a job enqueued only in the second queue" do
          let(:time) { Time.now }
          let!(:jid) do
            Timecop.freeze(time) { TestJob.set(queue: "special").perform_async("test") }
          end

          it "returns a unit of work" do
            work = subject.retrieve_work
            expect(work).to be_an_instance_of(AtomicSidekiq::UnitOfWork)
          end

          it "returns unit of work from the special queue" do
            work = subject.retrieve_work
            expect(work.queue_name).to eq("queue:special")
          end
        end

        context "when there is a job enqueued in both queues" do
          let(:time) { Time.now }
          let!(:jid_special) do
            Timecop.freeze(time) { TestJob.set(queue: "special").perform_async("test") }
          end
          let!(:jid_default) do
            Timecop.freeze(time) { TestJob.set(queue: "default").perform_async("test2") }
          end

          it "returns a unit of work" do
            work = subject.retrieve_work
            expect(work).to be_an_instance_of(AtomicSidekiq::UnitOfWork)
          end

          it "returns unit of work from first queue" do
            allow_any_instance_of(Array).to receive(:shuffle).and_return(["queue:special", "queue:default"])
            work = subject.retrieve_work
            expect(work.queue_name).to eq("queue:default")
          end
        end
      end
    end
  end
end
