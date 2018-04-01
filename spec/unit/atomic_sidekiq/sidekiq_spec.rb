RSpec.describe Sidekiq do
  describe ".atomic_fetch!" do
    context "when no configuration is given" do
      it "sets the Sidekiq fetcher to AtomicFetch" do
        Sidekiq.atomic_fetch!
        expect(Sidekiq.options[:fetch]).to eql(AtomicSidekiq::AtomicFetch)
      end

      it "sets the AtomicFetch configuration empty" do
        Sidekiq.atomic_fetch!
        expect(Sidekiq.options[:atomic_fetch]).to eql({})
      end
    end

    context "when a configuration hash is given" do
      configuration = { collection_interval: 500 }

      it "sets the Sidekiq fetcher to AtomicFetch" do
        Sidekiq.atomic_fetch!(configuration)
        expect(Sidekiq.options[:fetch]).to eql(AtomicSidekiq::AtomicFetch)
      end

      it "sets the AtomicFetch to the given configuration" do
        Sidekiq.atomic_fetch!(configuration)
        expect(Sidekiq.options[:atomic_fetch]).to eql(collection_interval: 500)
      end
    end
  end
end
