RSpec.describe AtomicSidekiq::InFlightKeymaker do
  subject { described_class.new("flight") }

  describe ".new" do
    it "initializes an instance of AtomicSifekiq::InFlightKeymaker" do
      expect(subject).to be_an_instance_of(AtomicSidekiq::InFlightKeymaker)
    end
  end

  describe "#matcher" do
    it "returns the in-flight prefix with a wildcard matcher" do
      matcher = subject.matcher
      expect(matcher).to eq("flight:*")
    end
  end

  describe "#job_key" do
    context "when given job is a string" do
      let(:job) { '{"class":"TestJob","jid":"abcdef123456xyz","queue":"special","created_at":"1234567890"}' }

      it "returns the in-flight key for the given job " do
        key = subject.job_key(job)
        expect(key).to eq("flight:special:abcdef123456xyz")
      end
    end

    context "when given job is a hash" do
      let(:job) { { "class" => "TestJob", "jid" => "abcdef123456xyz", "queue" => "special", "created_at" => "1234567890" } }

      it "returns the in-flight key for the given job " do
        key = subject.job_key(job)
        expect(key).to eq("flight:special:abcdef123456xyz")
      end
    end
  end

  describe "#queue_prefix" do
    context "when queue has a queue: prefix" do
      it "returns the in-flight key prefix for the given queue" do
        prefix = subject.queue_prefix("queue:default")
        expect(prefix).to eq("flight:default:")
      end
    end

    context "when queue does not have a prefix" do
      it "returns the in-flight key prefix for the given queue" do
        prefix = subject.queue_prefix("default")
        expect(prefix).to eq("flight:default:")
      end
    end
  end

  describe "#queue_matcher" do
    it "returns the queue prefix with a wildcard matcher" do
      allow(subject).to receive(:queue_prefix).with("queue:default").and_return("flight:default:")
      prefix = subject.queue_matcher("queue:default")
      expect(prefix).to eq("flight:default:*")
    end
  end

  describe "#job_matcher" do
    it "returns the jid with a wildcard matcher for the queue" do
      matcher = subject.job_matcher("abcd12345")
      expect(matcher).to eq("flight:*:abcd12345")
    end
  end
end
