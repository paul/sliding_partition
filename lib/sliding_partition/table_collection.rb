
require_relative "partition_table"

module SlidingPartition
  class TableCollection
    extend Forwardable
    include Enumerable

    attr_reader :definition, :time

    delegate %i[ inherited_table_name time_column suffix
                 partition_interval retention_interval lead_time ] => :definition

    def initialize(definition:, at_time:)
      @definition, @time = definition, at_time
    end

    def tables
      @tables ||= begin
        (first_timestamp.to_i...last_timestamp.to_i).step(partition_interval).map do |partition_time|
          PartitionTable.new(for_time: Time.at(partition_time), definition: definition)
        end
      end
    end

    def each(&block)
      tables.each(&block)
    end

    def first_timestamp
      @first_timestamp ||= if retention_interval == :forever
                             earliest_record_timestamp
                           else
                             time - retention_interval
                           end
    end

    def last_timestamp
      time + lead_time + partition_interval
    end

    def first_partition_timestamp
      tables.first.timestamp_floor
    end

    def earliest_record_timestamp
      definition.model.order("#{time_column} ASC").limit(1).first[time_column]
    end
  end
end
