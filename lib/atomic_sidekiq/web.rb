module AtomicSidekiq
  module Web
    VIEW_PATH = File.expand_path("../../web/views", __dir__)

    def self.registered(app)
      register_inflight(app)
      register_delete_inflight(app)
      register_recovered(app)
    end

    def self.register_inflight(app)
      app.get "/in-flight" do
        @jobs = AtomicSidekiq::InFlightQueue.new.list
        @total_size = @jobs.count
        @count = (params[:count] || 25).to_i
        @current_page = (params[:page] || 1).to_i

        start_idx = (@current_page - 1) * @count
        end_idx = (@current_page * @count) - 1
        @jobs = @jobs[start_idx..end_idx] || []

        erb File.read(File.join(VIEW_PATH, "in_flight.erb"))
      end
    end

    def self.register_delete_inflight(app)
      app.post "/in-flight/:jid/delete" do
        AtomicSidekiq::InFlightQueue.new.delete_job(route_params[:jid])

        redirect "#{root_path}in-flight"
      end
    end

    def self.register_recovered(app)
      app.get "/recovered" do
        @queues = AtomicSidekiq::RecoveredStats.new.stats_by_queue
        @jobs = AtomicSidekiq::RecoveredStats.new.stats_by_job

        erb File.read(File.join(VIEW_PATH, "recovered.erb"))
      end
    end
  end
end

if defined?(Sidekiq::Web)
  Sidekiq::Web.register(AtomicSidekiq::Web)
  Sidekiq::Web.tabs["In-flight"] = "in-flight"
  Sidekiq::Web.tabs["Recovered"] = "recovered"
end
