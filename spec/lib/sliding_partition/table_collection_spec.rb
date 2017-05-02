require "spec_helper"

require "active_record"

RSpec.describe SlidingPartition::TableCollection do

  TestEvent = Class.new(ActiveRecord::Base)

  describe "setting lead_time" do
    context "when not set" do
      let(:definition) do
        SlidingPartition::Definition.new(TestEvent) do |config|
          config.time_column        = :event_at
          config.suffix             = "%Y%m%d"
          config.partition_interval = 1.month
          config.retention_interval = 6.months
        end
      end

      let(:timestamp) { Time.new(2017, 06, 10) }

      subject(:table_collection) { definition.partitions(at: timestamp) }

      it "should create a table one month in advance" do
        expect(table_collection.tables.last.table_name).to eq "test_events_20170701"
      end
    end

    context "when set" do
      let(:definition) do
        SlidingPartition::Definition.new(TestEvent) do |config|
          config.time_column        = :event_at
          config.suffix             = "%Y%m%d"
          config.partition_interval = 1.month
          config.retention_interval = 6.months
          config.lead_time          = 1.year
        end
      end

      let(:timestamp) { Time.new(2017, 06, 10) }

      subject(:table_collection) { definition.partitions(at: timestamp) }

      it "should create a table one year in advance" do
        expect(table_collection.tables.last.table_name).to eq "test_events_20180701"
      end
    end
  end
end

