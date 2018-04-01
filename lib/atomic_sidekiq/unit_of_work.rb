module AtomicSidekiq
  class UnitOfWork
    attr_reader :queue, :job

    def initialize(queue = nil, job = nil,
                   in_flight_prefix: AtomicFetch::IN_FLIGHT_KEY_PREFIX)
      @queue          = queue
      @job            = job
      @acknowledge_op = AtomicOperation::Acknowledge.new(
        in_flight_prefix: in_flight_prefix
      )
      @requeue_op = AtomicOperation::Requeue.new(
        in_flight_prefix: in_flight_prefix
      )
    end

    def acknowledge
      acknowledge_op.perform(queue: queue, job: job)
    end

    def queue_name
      "queue:#{queue.sub(/.*queue:/, '')}"
    end

    def requeue
      requeue_op.perform(queue: queue, job: job)
    end

    private

    attr_reader :acknowledge_op, :requeue_op
  end
end
