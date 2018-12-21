module AtomicSidekiq
  class InFlightQueue
    def initialize
      @keymaker = InFlightKeymaker.new(AtomicFetch::IN_FLIGHT_KEY_PREFIX)
    end

    def list
      keys = list_keys
      retrieve_jobs(keys)
    end

    def delete_job(jid)
      job_matcher = keymaker.job_matcher(jid)
      job_keys = retrieve_keys(job_matcher)
      return 0 if job_keys.empty?

      Sidekiq.redis { |conn| conn.del(*job_keys) }
    end

    private

    attr_reader :keymaker

    def list_keys
      matcher = keymaker.matcher
      result = []
      it = 0
      loop do
        it, keys = Sidekiq.redis { |conn| conn.scan(it, match: matcher) }
        result.concat(keys)
        it = it.to_i
        break if it.zero?
      end
      result
    end

    def retrieve_jobs(keys)
      Sidekiq.redis do |conn|
        keys.map { |key| JSON.parse(conn.get(key)) }
      end
    end

    def retrieve_keys(key_wildcard)
      Sidekiq.redis { |conn| conn.keys(key_wildcard) }
    end
  end
end
