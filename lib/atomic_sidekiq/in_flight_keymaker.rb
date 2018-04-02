module AtomicSidekiq
  class InFlightKeymaker
    def initialize(key_prefix)
      @key_prefix = key_prefix
    end

    def queue_prefix(queue)
      normalized_name = queue.gsub(/queue:/, "")
      "#{key_prefix}:#{normalized_name}:"
    end

    def queue_matcher(queue)
      "#{queue_prefix(queue)}*"
    end

    def job_key(job)
      obj = job
      obj = JSON.parse(obj) if job.is_a?(String)
      "#{key_prefix}:#{obj['queue']}:#{obj['jid']}"
    end

    def job_matcher(jid)
      "#{key_prefix}:*:#{jid}"
    end

    private

    attr_reader :key_prefix
  end
end
