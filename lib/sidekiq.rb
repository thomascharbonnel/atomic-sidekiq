module Sidekiq
  def self.atomic_fetch!(opts = {})
    self.options[:fetch] = AtomicSidekiq::AtomicFetch
    self.options[:atomic_fetch] = opts
  end
end
