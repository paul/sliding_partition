require "spec_helper"

require "active_record"

RSpec.describe SlidingPartition do

  Event = Class.new(ActiveRecord::Base)

  before do
    SlidingPartition.define(Event) do |partition|
      partition.time_column        = :event_at
      partition.suffix             = "%Y%m%d"
      partition.partition_interval = 1.month
      partition.retention_interval = 6.months
    end
  end

  describe "definining partitions" do
    it "should add it to the list of known parititions" do
      expect(SlidingPartition.parititions.size).to be 1
    end
  end

end

