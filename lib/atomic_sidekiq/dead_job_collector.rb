module AtomicSidekiq
  class DeadJobCollector
    class << self
      def collect!(queues, in_flight_keymaker:, skip_recovery_queues: [])
        queues.each do |q|
          new(q, in_flight_keymaker: in_flight_keymaker)
            .collect!(skip_recovery: skip_recovery_queues.include?(q))
        end
      end
    end

    def initialize(queue, in_flight_keymaker:)
      @recovered_stats    = RecoveredStats.new
      @queue              = queue
      @in_flight_keymaker = in_flight_keymaker
      @expire_op          = AtomicOperation::Expire.new
    end

    def collect!(skip_recovery: false)
      each_keys { |job_key| expire!(job_key, skip_recovery: skip_recovery) }
    end

    private

    attr_reader :queue, :in_flight_keymaker, :expire_op, :recovered_stats

    def expire!(job_key, skip_recovery:)
      recovered = expire_op.perform(queue, job_key, recover: !skip_recovery)
      return if recovered.nil?

      job = JSON.parse(recovered[1])
      recovered_stats.increment!(job)
      job
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
