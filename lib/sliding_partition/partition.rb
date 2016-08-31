
require_relative "partition_table"

module SlidingPartition
  class Partition

    attr_accessor :inherited_table_name, :time_column, :suffix,
                  :partition_interval, :retention_interval

    def initialize(name)
      @inherited_table_name = name
      yield self if block_given?
    end

    def initialize!(time: Time.now)
      tables(at_time: time).each do |table|
        create_table(table) unless table_exists?(table)
      end
    end

    def rotate!(time: Time.now)
      initialize!(time: time) # creates the next table
      connection.tables.each do |candidate|
        next unless candidate.starts_with?(inherited_table_name.to_s + "_")

        table_time = begin
          Time.strptime(candidate, [inherited_table_name, suffix].join("_"))
        rescue ArgumentError
          next
        end

        next if table_time >= first_partition_timestamp(time: time)

        drop_table(candidate)
      end
    end

    def tables(at_time:)
      first_partition_timestamp = at_time - retention_interval
      last_partition_timestamp = at_time + partition_interval

      (first_partition_timestamp.to_i...last_partition_timestamp.to_i).step(partition_interval).map do |partition_time|
        PartitionTable.new(for_time: Time.at(partition_time), partition_config: self)
      end

    end

    def floor_timestamp(timestamp)
      Time.at((timestamp.to_f / retention_interval).floor * retention_interval)
    end

    def create_table(table)
      connection.execute(table.ddl)
    end

    def drop_table(table)
      connection.drop_table(table)
    end

    def table_exists?(table)
      connection.tables.include?(table.table_name)
    end

    def connection
      ActiveRecord::Base.connection
    end

    def first_partition_timestamp(time: Time.now)
      time - retention_interval
    end
  end
end
