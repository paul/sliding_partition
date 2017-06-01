
require_relative "partition_ddl_changer"
require_relative "table_collection"

module SlidingPartition
  class Definition

    attr_reader :model

    attr_accessor :inherited_table_name, :time_column, :suffix,
                  :partition_interval, :retention_interval,
                  :lead_time, :before_rotate

    def initialize(model)
      @model = model
      set_defaults
      yield self if block_given?
    end

    def setup!(at: Time.now)
      PartitionDDLChanger.new(self, at).setup!
    end

    def rotate!(at: Time.now)
      PartitionDDLChanger.new(self, at).rotate!
    end

    def migrate!(at: Time.now, quiet: false)
      PartitionDDLChanger.new(self, at, quiet: quiet).migrate!
    end

    def partitions(at: Time.now)
      TableCollection.new(definition: self, at_time: at)
    end

    def final_copy!(at: Time.now, quiet: false)
      PartitionDDLChanger.new(self, at, quiet: quiet).migrate!
    end

    def inherited_table_name
      @inherited_table_name ||= model.table_name
    end

    private

    def set_defaults
      @lead_time = 0
      @before_rotate = lambda { |_| }
    end

  end
end
