module AtomicSidekiq
  module Heartbeat
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def heartbeat!(timeout = nil)
        heartbeat_operation.perform(
          jid: jid,
          timeout: timeout || default_heartbeat_timeout
        )
      end

      private

      def default_heartbeat_timeout
        AtomicSidekiq::AtomicFetch::DEFAULT_EXPIRATION_TIME
      end

      def heartbeat_operation
        @heartbeat_operation ||= AtomicSidekiq::AtomicOperation::Heartbeat.new(
          in_flight_keymaker: keymaker
        )
      end

      def keymaker
        @keymaker ||= AtomicSidekiq::InFlightKeymaker.new(
          AtomicSidekiq::AtomicFetch::IN_FLIGHT_KEY_PREFIX
        )
      end
    end
  end
end
