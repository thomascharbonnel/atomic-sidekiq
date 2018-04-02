module AtomicSidekiq
  module AtomicOperation
    class Expire < Base
      EXPIRE_SCRIPT = File.read(
        File.join(File.dirname(__FILE__),
                  "./lua_scripts/expire.lua")
      )

      def initialize
        super(in_flight_keymaker: nil)
      end

      def perform(queue, in_flight_key)
        redis do |conn|
          conn.eval(EXPIRE_SCRIPT, [queue, in_flight_key], [Time.now.utc.to_i])
        end
      end
    end
  end
end
