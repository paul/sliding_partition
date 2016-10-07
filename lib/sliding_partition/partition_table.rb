
require "rounding"

module SlidingPartition
  class PartitionTable
    extend Forwardable

    attr_reader :timestamp, :definition

    delegate %i[ inherited_table_name time_column suffix
                 partition_interval retention_interval ] => :definition

    def initialize(for_time:, definition:)
      @timestamp, @definition = for_time, definition
    end

    def table_name
      [
        inherited_table_name,
        timestamp_floor.strftime(suffix)
      ].join("_")
    end

    def timestamp_floor
      # rounding doesn't handle months correctly, do it ourselves
      if partition_interval = 1.month
        @timestamp.beginning_of_month.floor_to(1.day)
      else
        @timestamp.floor_to(partition_interval)
      end
    end

    def timestamp_ceiling
      if partition_interval = 1.month
        @timestamp.end_of_month + 1
      else
        @timestamp.ceiling_to(partition_interval)
      end
    end

  end
end
