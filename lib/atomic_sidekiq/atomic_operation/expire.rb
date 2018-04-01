module AtomicSidekiq
  module AtomicOperation
    class Expire < Base
      def initialize
        super(in_flight_prefix: nil)
      end

      def perform(queue, in_flight_key)
        redis do |conn|
          conn.eval(EXPIRE_SCRIPT, [queue, in_flight_key], [Time.now.utc.to_i])
        end
      end

      private

      EXPIRE_SCRIPT = File.read(File.join(File.dirname(__FILE__), './lua_scripts/expire.lua'))
    end
  end
end
