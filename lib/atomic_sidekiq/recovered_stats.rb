module AtomicSidekiq
  class RecoveredStats
    def increment!(job)
      puts "INCREMENTING"
      increment_by_job!(job["class"])
      increment_by_queue!(job["queue"])
    end

    def stats_by_queue
      iterate_stats(queue_prefix)
    end

    def stats_by_job
      iterate_stats(job_prefix)
    end

    private

    def iterate_stats(prefix)
      iterate_keys(prefix).map do |key|
        value = Sidekiq.redis { |conn| conn.get(key) }
        [key.gsub(Regexp.new("#{prefix}:"), ""), value]
      end.to_h
    end

    def iterate_keys(prefix)
      it = 0
      result = []
      loop do
        it, keys = Sidekiq.redis { |conn| conn.scan(it, match: "#{prefix}:*") }
        result.concat(keys)
        it = it.to_i
        return result if it.zero?
      end
    end

    def increment_by_job!(job_name)
      Sidekiq.redis { |conn| conn.incr("#{job_prefix}:#{job_name}") }
    end

    def increment_by_queue!(queue)
      Sidekiq.redis { |conn| conn.incr("#{queue_prefix}:#{queue}") }
    end

    def prefix
      "atomic_sidekiq"
    end

    def queue_prefix
      "#{prefix}:queue"
    end

    def job_prefix
      "#{prefix}:job"
    end
  end
end
