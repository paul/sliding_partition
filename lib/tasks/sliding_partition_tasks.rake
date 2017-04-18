# frozen_string_literal: true

require "sliding_partition"

namespace :partition do
  desc "Setup all postgres sliding partitions"
  task :setup => :environment do
    SlidingPartition.setup!
  end

  desc "Migrate data in all partitions"
  task :migrate => :environment do
    SlidingPartition.migrate!
  end

  desc "Copy missing data"
  task :final_copy => :environment do
    SlidingPartition.final_copy!
  end
end
