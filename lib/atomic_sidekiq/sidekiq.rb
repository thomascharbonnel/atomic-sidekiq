module Sidekiq
  def self.atomic_fetch!(opts = {})
    options[:fetch] = AtomicSidekiq::AtomicFetch
    options[:atomic_fetch] = opts
  end
end
