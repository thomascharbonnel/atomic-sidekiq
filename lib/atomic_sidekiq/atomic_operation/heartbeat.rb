module AtomicSidekiq
  module AtomicOperation
    class Heartbeat < Base
      HEARTBEAT_SCRIPT = File.read(
        File.join(File.dirname(__FILE__),
                  "./lua_scripts/heartbeat.lua")
      )

      def perform(jid:, timeout:)
        key = in_flight_job_key(jid)
        return unless key

        redis do |conn|
          conn.eval(HEARTBEAT_SCRIPT, [key], [expiration_date(timeout)])
        end
      end

      private

      def expiration_date(timeout)
        Time.now.utc.to_i + timeout
      end

      def in_flight_job_key(jid)
        matcher = in_flight_keymaker.job_matcher(jid)
        it = 0
        loop do
          it, keys = redis { |conn| conn.scan(it, match: matcher) }
          return keys[0] if keys.count > 0

          it = it.to_i
          return if it.zero?
        end
      end
    end
  end
end
