
require_relative "partition_table"

module SlidingPartition
  class TableCollection
    extend Forwardable
    include Enumerable

    attr_reader :definition, :time

    delegate %i[ inherited_table_name time_column suffix
                 partition_interval retention_interval ] => :definition

    def initialize(definition:, at_time:)
      @definition, @time = definition, at_time
    end

    def tables
      first_ts = time - retention_interval
      last_ts = time + partition_interval
      (first_ts.to_i...last_ts.to_i).step(partition_interval).map do |partition_time|
        PartitionTable.new(for_time: Time.at(partition_time), definition: definition)
      end
    end

    def each(&block)
      tables.each(&block)
    end

    def first_partition_timestamp
      tables.first.timestamp_floor
    end

  end
end
