
require "rounding"

module SlidingPartition
  class PartitionTable
    def initialize(for_time:, partition_config:)
      @timestamp, @config = for_time, partition_config
    end

    def table_name
      [
        @config.inherited_table_name,
        floored_timestamp.strftime(@config.suffix)
      ].join("_")
    end

    def ddl
      <<-SQL
        CREATE TABLE #{table_name} (
          LIKE #{@config.inherited_table_name} INCLUDING ALL
        ) INHERITS (#{@config.inherited_table_name});

        ALTER TABLE #{table_name}
        ADD CHECK (
          #{@config.time_column} >= '#{floored_timestamp.to_s(:db)}' AND
          #{@config.time_column} <  '#{next_partition_table.floored_timestamp.to_s(:db)}'
        )
      SQL
    end

    def floored_timestamp
      # rounding doesn't handle months correctly, do it ourselves
      if partition_interval = 1.month
        @timestamp.change(day: 1, hour: 0)
      else
        @timestamp.floor_to(partition_interval)
      end
    end

    def next_partition_table
      PartitionTable.new(for_time: @timestamp + @config.partition_interval,
                         partition_config: @config)
    end

    def partition_interval
      @config.partition_interval
    end
  end
end
