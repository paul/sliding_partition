# frozen_string_literal: true

require "sliding_partition"

namespace :partition do
  task :setup do
    SlidingPartition.setup!
  end
end
