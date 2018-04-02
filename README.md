[![Gem Version](https://badge.fury.io/rb/atomic-sidekiq.svg)](https://badge.fury.io/rb/atomic-sidekiq) [![Build Status](https://travis-ci.org/Colex/atomic-sidekiq.svg?branch=master)](https://travis-ci.org/Colex/atomic-sidekiq) [![codecov](https://codecov.io/gh/Colex/atomic-sidekiq/branch/master/graph/badge.svg)](https://codecov.io/gh/Colex/atomic-sidekiq)

# AtomicSidekiq
AtomicSidekiq implements a reliable way of processing jobs using Sidekiq. By default, Sidekiq will retrieve jobs from the queue by removing it from Redis. If the job fails to complete (e.g. the process terminates unexpectdly mid-job), the job will be lost forever. This can be acceptable in many applications, but some application require higher levels of reliability, hence AtomicSidekiq will not erase any job from Redis until it's acknowledged that they have finished - otherwise, they are re-scheduled.

The algorithm used by AtomicSidekiq supports both queue prioritization mechanisms: strict priority and weighted random.

## Requirements
AtomicSidekiq supports only Sidekiq 5+.

## Installation
```
gem install atomic-sidekiq
```

Add to your server configuration (or create a new one if you don't have):
```ruby
Sidekiq.configure_server do |config|
  config.atomic_fetch!
end
```

## Configuration
By default, jobs will expire and be re-queued after 1 hour if not acknowledged, and the "Collector" will check if for expired jobs every 60 seconds. This can be reconfigured as desired: _(Note that collection adds some overhead)_
```ruby
Sidekiq.configure_server do |config|
  config.atomic_fetch!({
    collection_interval: 5, # Unit: seconds
    expiration_time: 1800   # Unit: seconds (30 minutes)
  })
end
```

## Heartbeat
For long running jobs that may run for an unpredictable amounts of time, you may send periodic heartbeats to reset the expiration time and allow the job to run for longer (if the job stops sending heartbeats and the expiration date run out, the job will be assumed lost and recovered). Example:

```ruby
class LongRunningWorker
  include Sidekiq::Worker
  include AtomicSidekiq::Heartbeat

  def perform
    (1..10_000).each do
      ExampleClass.long_running_action!
      heartbeat! # You can also give a specific timeout period, e.g. heartbeat!(1.hour)
    end
  end
end
```

## Benchmark
### Reliability
This benchmark tests Sidekiq's ability to recover from unexpected failures. The test script forces a failure randomly 1% of the time it's running a job and measures how many jobs are able to be completed:

| Version       | Queued  | Processed | Lost  |
|---------------|---------|-----------|-------|
| Sidekiq       | 10,000  | 1,838     | 8,162 |
| AtomicSidekiq | 10,000  | 10,000    | 0     |

Since jobs run in parallel, when the process crashes it loses all jobs that had been retrieved and were running at the moment. AtomicSidekiq manage to retrieve all jobs and finish the work. The reliability script can be found at `./bin/sidekiqfail`. It terminates and restores Sidekiq several times until all jobs are processed or a maximum number of tries is reached.

The test script can be run with the flag `-a` to use the **AtomicSidekiq::AtomicFetch** and without any flags to run with the default Sidekiq fetcher.

_(Note: Sidekiq PRO comes with its own reliable fetcher, no benchmarks were run against that version. Only the free version has been tested)_

### Performance
The performance test uses the default settings for both fetchers (default and AtomicFetch) and times how long Sidekiq takes to process two loads, one of 10,000 and another one of 100,000 jobs.

| Version       | Time Ellapsed (10k) | Throughput (10k) | Time Ellapsed (100k) | Throughput (100k) |
|---------------|---------------------|------------------|----------------------|-------------------|
| Sidekiq       | 6s                  | 166 jobs/sec     | 30s                  | 3,333 jobs/sec    |
| AtomicSidekiq | 8s                  | 125 jobs/sec     | 1m10s                | 1,429 jobs/sec    |

The reliability improvements of AtomicSidekiq come at the cost of less throughput. AtomicSidekiq's algorithm is linear instead of constant like Sidekiq's default, meaning that the cost of performance increases linearly as more jobs are added to the queue.

## Web
AtomicSidekiq provides two different pages for checking stats on the job reliability. One shows which jobs are currently "in-flight" status (even if they might have exited uexpectedly) and how long before they expire. A second page shows how many jobs have been recovered by queue and by worker class.

[Screenshot in-flight here]
_"Estimated Lost"_ shows how many jobs in-flight might have been lost (this is calculated by looking how many jobs are in "Busy" and how many are "In-flight").

[Screenshot recovered here]

## Tests
```sh
bundle exec rspec
```

You may also run the tests with Docker using `docker-compose` (it will automatially start a Redis server for the integration tests):
```sh
docker-compose run test
```

## Caveat
This ensures that your job will be run completely **at least once**. It may run more than once if your job fails to acknowledge (e.g. the process terminates after performing a job but right before the ack is sent). _Note: This is better than the default Sidekiq though, which cannot give any guarantees on the number of times a job will be run._
