module AtomicSidekiq
  class DeadJobCollector
    class << self
      def collect!(queues, in_flight_keymaker:)
        queues.each do |q|
          new(q, in_flight_keymaker: in_flight_keymaker).collect!
        end
      end
    end

    def initialize(queue, in_flight_keymaker:)
      @queue              = queue
      @in_flight_keymaker = in_flight_keymaker
      @expire_op          = AtomicOperation::Expire.new
    end

    def collect!
      each_keys { |job_key| expire!(job_key) }
    end

    private

    attr_reader :queue, :in_flight_keymaker, :expire_op

    def expire!(job_key)
      expire_op.perform(queue, job_key)
    end

    def each_keys
      it = 0
      Sidekiq.redis do |conn|
        loop do
          it, job_keys = conn.scan(it, match: keys_prefix)
          it = it.to_i
          job_keys.each { |job_key| yield(job_key) }
          break if it.zero?
        end
      end
    end

    def keys_prefix
      in_flight_keymaker.queue_matcher(queue)
    end
  end
end
