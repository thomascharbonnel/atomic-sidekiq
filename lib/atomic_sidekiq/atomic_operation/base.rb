module AtomicSidekiq
  module AtomicOperation
    class Base
      def initialize(in_flight_keymaker:)
        @in_flight_keymaker = in_flight_keymaker
      end

      protected

      attr_reader :in_flight_keymaker

      def redis
        Sidekiq.redis { |conn| yield(conn) }
      end
    end
  end
end
