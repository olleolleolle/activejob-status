require 'activejob-status/storage'
require 'activejob-status/pub'
require 'activejob-status/sub'
require 'activejob-status/progress'

module ActiveJob::Status
  extend ActiveSupport::Concern
  DEFAULT_EXPIRY = 60 * 30

  included do
    before_enqueue {|job| job.status.update(status: :queued) }
    before_perform {|job| job.status.update(status: :working) }
    after_perform  {|job| job.status.update(status: :completed) }

    rescue_from(Exception) do |e|
      self.status.update(status: :failed)
      raise e
    end
  end

  def status
    @status ||= Pub.new(self)
  end

  def progress
    @progress ||= Progress.new(self)
  end

  class << self
    def store= store
      store = ActiveSupport::Cache.lookup_store(store) if store.is_a?(Symbol)
      @@store = store
    end

    def store
      @@store ||= (defined?(Rails) && Rails.cache)
    end

    def get(id)
      Sub.new(id)
    end

    def pub(id)
      Pub.new(id)
    end
  end
end