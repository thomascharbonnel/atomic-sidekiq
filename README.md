# AtomicSidekiq
AtomicSidekiq implements a reliable way of processing jobs using Sidekiq. By default, Sidekiq will retrieve jobs from the queue by removing it from Redis. If the job fails to complete (e.g. the process terminates unexpectdly mid-job), the job will be lost forever. This can be acceptable in many applications, but some application require higher levels of reliability, hence AtomicSidekiq will not erase any job from Redis until it's acknowledged that they have finished - otherwise, they are re-scheduled.

## Benchmark
### Reliability
This benchmark tests Sidekiq's ability to recover from unexpected failures. The test script forces a failure randomly 1% of the time it's running a job and measures how many jobs are able to be completed:

| Version       | Queued  | Processed | Lost  |
|---------------|---------|-----------|-------|
| Sidekiq       | 10,000  | 8,162     | 8,162 |
| AtomicSidekiq | 10,000  | 10,000    | 0     |

Since jobs run in parallel, when the process crashes it loses all jobs that had been retrieved and were running at the moment. AtomicSidekiq manage to retrieve all jobs and finish the work. The reliability script can be found at `./bin/sidekiqrecovery`. It terminates and restores Sidekiq several times until all jobs are processed or a maximum number of tries is reached.

_(Note: Sidekiq PRO comes with its own reliable fetcher, no benchmarks were run against that version. Only the free version has been tested)_

## Installation
```
gem install atomic-sidekiq
```

Add to your server configuration (or create a new one if you don't have):
```ruby
Sidekiq.configure_server do |config|
  config.options[:fetch] = AtomicSidekiq::AtomicFetch
end
```

## Caveat
This ensures that your job will be run completely **at least once**. It may run more than once if your job fails to acknowledge (e.g. the process terminates after performing a job but right before the ack is sent). _Note: This is better than the default Sidekiq though, which cannot give any guarantees on the number of times a job will be run._
