module AtomicSidekiq
  module AtomicOperation
    class Requeue < Base
      def perform(queue:, job:)
        redis do |conn|
          requeue(conn, queue: queue, job: job)
        end
      end

      private

      def requeue(conn, queue:, job:)
        conn.multi do
          conn.rpush(queue, job)
          conn.del(in_flight_keymaker.job_key(job))
        end
      end
    end
  end
end
