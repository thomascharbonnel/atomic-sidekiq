module AtomicSidekiq
  class AtomicFetch
    IN_FLIGHT_KEY_PREFIX = "flight:"
    IDLE_TIMEOUT = 2 # seconds
    DEFAULT_EXPIRATION = 1 # seconds
    COLLECTION_TIMEOUT = 1 # seconds

    def initialize(options)
      @retrieve_op = AtomicOperation::Retrieve.new(in_flight_prefix: IN_FLIGHT_KEY_PREFIX)
      @strictly_ordered_queues = !!options[:strict]
      @@next_collection ||= Time.now
      set_queues(options)
    end

    def retrieve_work
      collect_dead_jobs!
      work = retrieve_op.perform(ordered_queues, expire_at)
      UnitOfWork.new(*work) if work
    end

    private

    attr_reader :retrieve_op, :queues, :strictly_ordered_queues

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
      @@next_collection = Time.now + COLLECTION_TIMEOUT
      DeadJobCollector.collect!(ordered_queues)
    end

    def expire_at
      Time.now.utc.to_i + DEFAULT_EXPIRATION
    end
  end
end
