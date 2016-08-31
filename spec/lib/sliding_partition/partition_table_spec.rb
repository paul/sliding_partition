
require "spec_helper"

require "sliding_partition/partition_table"

require "active_support/core_ext/integer/time"

ENV["TZ"] = "UTC"

RSpec.describe SlidingPartition::PartitionTable do

  let(:partition) do
    SlidingPartition::Partition.new(:test_events) do |partition|
      partition.suffix = "%Y%m%d"
      partition.partition_interval = partition_interval
      partition.retention_interval = 6.months
    end
  end


  describe "#floored_timestamp" do
    context "interval 1 month" do
      let(:timestamp) { DateTime.parse("2016-03-05T06:07:08") }
      let(:partition_interval) { 1.month }

      let(:table) { SlidingPartition::PartitionTable.new(for_time: timestamp, partition_config: partition) }

      subject(:floored_timestamp) { table.floored_timestamp }

      it { should eq DateTime.new(2016, 3, 1) }

    end

  end

end
