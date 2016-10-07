# frozen_string_literal: true

module SlidingPartition
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load "tasks/sliding_partition_tasks.rake"
    end
  end
end

