module AtomicSidekiq
  class DeadJobCollector
    class << self
      def collect!(queues)
        queues.each { |q| new(q).collect! }
      end
    end

    def initialize(queue, in_flight_prefix: AtomicFetch::IN_FLIGHT_KEY_PREFIX)
      @queue            = queue
      @in_flight_prefix = in_flight_prefix
      @expire_op        = AtomicOperation::Expire.new
    end

    def collect!
      Sidekiq.logger.error("Collecting jobs: #{queue}")
      each_keys { |job_key| expire!(job_key) }
    end

    private

    attr_reader :queue, :in_flight_prefix, :expire_op

    def expire!(job_key)
      Sidekiq.logger.error("Expiring: #{job_key}")
      expire_op.perform(queue, job_key)
    end

    def each_keys(&block)
      it = 0
      Sidekiq.redis do |conn|
        loop do
          it, job_keys = conn.scan(it, match: keys_prefix)
          it = it.to_i
          job_keys.each { |job_key| block.call(job_key) }
          break if it == 0
        end
      end
    end

    def keys_prefix
      "#{in_flight_prefix}#{queue}:*"
    end
  end
end
