# rubocop:disable Style/ClassVars
module AtomicSidekiq
  class AtomicFetch
    IN_FLIGHT_KEY_PREFIX = "flight".freeze
    DEFAULT_POLL_INTERVAL = 5 # seconds
    DEFAULT_EXPIRATION_TIME = 3600 # seconds
    DEFAULT_COLLECTION_INTERVAL = 60 # seconds

    def initialize(options, in_flight_keymaker: nil)
      @keymaker = in_flight_keymaker ||
                  InFlightKeymaker.new(IN_FLIGHT_KEY_PREFIX)

      @retrieve_op = AtomicOperation::Retrieve.new(
        in_flight_keymaker: keymaker
      )

      @queues ||= options[:queues].map { |q| "queue:#{q}" }
      @strictly_ordered_queues = !!options[:strict]
      @@next_collection ||= Time.now

      configure_atomic_fetch(options.fetch(:atomic_fetch, {}))
    end

    def retrieve_work
      collect_dead_jobs!
      work = retrieve_op.perform(ordered_queues, expire_at)
      return UnitOfWork.new(*work, in_flight_keymaker: keymaker) if work
      sleep(poll_interval)
      nil
    end

    private

    attr_reader :retrieve_op, :queues, :strictly_ordered_queues,
                :collection_interval, :poll_interval, :expiration_time,
                :keymaker

    def configure_atomic_fetch(options)
      @expiration_time = options[:expiration_time] || DEFAULT_EXPIRATION_TIME
      @collection_interval = options[:collection_wait_time] ||
                             DEFAULT_COLLECTION_INTERVAL
      @poll_interval = options[:poll_interval] || DEFAULT_POLL_INTERVAL
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
      DeadJobCollector.collect!(ordered_queues, in_flight_keymaker: keymaker)
    end

    def expire_at
      Time.now.utc.to_i + expiration_time
    end
  end
end
# rubocop:enable Style/ClassVars
