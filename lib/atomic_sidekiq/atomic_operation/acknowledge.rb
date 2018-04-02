module AtomicSidekiq
  module AtomicOperation
    class Acknowledge < Base
      def perform(job:)
        redis do |conn|
          conn.del(in_flight_keymaker.job_key(job))
        end
      end
    end
  end
end
