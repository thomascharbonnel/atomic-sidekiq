module AtomicSidekiq
  class AtomicFetch
    IN_FLIGHT_KEY_PREFIX = "flight:"
    DEFAULT_POLL_INTERVAL = 10 # seconds
    DEFAULT_EXPIRATION_TIME = 3600 # seconds
    DEFAULT_COLLECTION_INTERVAL = 60 # seconds

    def initialize(options)
      @retrieve_op = AtomicOperation::Retrieve.new(in_flight_prefix: IN_FLIGHT_KEY_PREFIX)
      @strictly_ordered_queues = !!options[:strict]

      atomic_fetch_opts = options.fetch(:atomic_fetch, {})
      @expiration_time = atomic_fetch_opts.fetch(:expiration_time, DEFAULT_EXPIRATION_TIME)
      @collection_interval = atomic_fetch_opts.fetch(:collection_wait_time, DEFAULT_COLLECTION_INTERVAL)
      @poll_interval = atomic_fetch_opts.fetch(:poll_interval, DEFAULT_POLL_INTERVAL)
      @@next_collection ||= Time.now
      set_queues(options)
    end

    def retrieve_work
      collect_dead_jobs!
      work = retrieve_op.perform(ordered_queues, expire_at)
      return UnitOfWork.new(*work) if work
      sleep(poll_interval)
      nil
    end

    private

    attr_reader :retrieve_op, :queues, :strictly_ordered_queues,
    :collection_interval, :poll_interval, :expiration_time

    def set_queues(options)
      @queues ||= options[:queues].map { |q| "queue:#{q}" }
    end

    def ordered_queues
      if strictly_ordered_queues
        queues
      else
        queues.shuffle.uniq
      end
    end

    def collect_dead_jobs!
      return if @@next_collection > Time.now
      @@next_collection = Time.now + collection_interval
      DeadJobCollector.collect!(ordered_queues)
    end

    def expire_at
      Time.now.utc.to_i + expiration_time
    end
  end
end
