# frozen_string_literal: true

module SlidingPartition
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load "tasks/sliding_partition_tasks.rake"
    end

    initializer "sliding_partition.load_jobs" do |app|
      require "sliding_partition/job" if defined?(ActiveJob)
    end
  end
end

