module AtomicSidekiq
  module AtomicOperation
    class Acknowledge < Base
      def perform(queue:, job:)
        redis do |conn|
          conn.del(in_flight_job_key(queue, job))
        end
      end
    end
  end
end
