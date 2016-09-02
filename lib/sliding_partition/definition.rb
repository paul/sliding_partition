
require_relative "partition_ddl_changer"
require_relative "table_collection"

module SlidingPartition
  class Definition

    attr_accessor :inherited_table_name, :time_column, :suffix,
                  :partition_interval, :retention_interval

    def initialize(name)
      @inherited_table_name = name
      yield self if block_given?
    end

    def setup!(at: Time.now)
      PartitionDDLChanger.new(self, at).setup!
    end

    def rotate!(at: Time.now)
      PartitionDDLChanger.new(self, at).rotate!
    end

    def partitions(at: Time.now)
      TableCollection.new(definition: self, at_time: at)
    end

  end
end
