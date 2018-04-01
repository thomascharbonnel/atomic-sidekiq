module AtomicSidekiq
  module AtomicOperation
    class Retrieve < Base
      def perform(queues, expire_at)
        queues.each do |queue|
          res = retrieve_from_queue(queue, expire_at.to_i)
          return res if res
        end
        nil
      end

      private

      RETRIEVE_SCRIPT = File.read(File.join(File.dirname(__FILE__), './lua_scripts/retrieve.lua'))

      def retrieve_from_queue(queue, expire_at)
        redis do |conn|
          conn.eval(RETRIEVE_SCRIPT, [queue, in_flight_prefix], [expire_at])
        end
      end
    end
  end
end
