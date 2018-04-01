module AtomicSidekiq
  module AtomicOperation
    class Base
      def initialize(in_flight_prefix:)
        @in_flight_prefix = in_flight_prefix
      end

      protected

      attr_reader :in_flight_prefix

      def redis
        Sidekiq.redis { |conn| yield(conn) }
      end

      def in_flight_job_key(queue, job)
        jid = JSON.parse(job)["jid"]
        "#{in_flight_prefix}#{queue}:#{jid}"
      end
    end
  end
end
