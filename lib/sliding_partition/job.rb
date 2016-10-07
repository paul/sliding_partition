
module SlidingPartition
  class Job < ::ApplicationJob

    def perform
      SlidingPartition.rotate!
    end

  end
end
