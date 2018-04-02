module AtomicSidekiq
  module Web
    VIEW_PATH = File.expand_path("../../web/views", __dir__)

    def self.registered(app)
      app.get "/in-flight" do
        Web.render_in_flight
      end

      app.get "/recovered" do
        Web.render_recovered
      end
    end

    def self.render_in_flight
      @jobs = AtomicSidekiq::InFlightQueue.new.list
      @total_size = @jobs.count
      @count = 25
      @current_page = (params[:page] || 1).to_i
      @jobs = @jobs[@current_page..(@current_page + @count)]
      erb File.read(File.join(VIEW_PATH, "in_flight.erb"))
    end

    def self.render_recovered
      @queues = AtomicSidekiq::RecoveredStats.new.stats_by_queue
      @jobs = AtomicSidekiq::RecoveredStats.new.stats_by_job
      erb File.read(File.join(VIEW_PATH, "recovered.erb"))
    end
  end
end

require "sidekiq/web" unless defined?(Sidekiq::Web)
Sidekiq::Web.register(AtomicSidekiq::Web)
Sidekiq::Web.tabs["In-flight"] = "in-flight"
Sidekiq::Web.tabs["Recovered"] = "recovered"
