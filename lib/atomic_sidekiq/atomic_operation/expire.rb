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

      def perform(queue, in_flight_key, recover:)
        redis do |conn|
          conn.eval(
            EXPIRE_SCRIPT,
            [
              queue, # Queue Name
              in_flight_key, # Key of the inflight job being expired
            ],
            [
              Time.now.utc.to_i, # Current time
              recover, # Boolean flag: should it be recovered if expired
            ]
          )
        end
      end
    end
  end
end
