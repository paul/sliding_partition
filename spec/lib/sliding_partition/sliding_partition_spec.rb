# frozen_string_literal: true

require "spec_helper"
ENV["TZ"] = "UTC"

require "active_record"
require "awesome_print"

RSpec.describe "SlidingPartition" do

  let(:master_connection) do
    ActiveRecord::Base.establish_connection connection_config.merge(database: "postgres", schema_search_path: "public")
    ActiveRecord::Base.connection
  end

  let(:connection_config) do
    {
      adapter: "postgresql",
      database: "sliding_partition_test"
    }
  end

  before do
    begin
      master_connection.create_database("sliding_partition_test")
    rescue ActiveRecord::StatementInvalid => error
      if /database .* already exists/ === error.message
        nil
      else
        raise
      end
    end

    connection.execute <<-SQL
      CREATE TABLE IF NOT EXISTS test_events (
        id         serial    PRIMARY KEY,
        name       varchar   NOT NULL,
        event_at   timestamp NOT NULL,

        result     varchar,

        created_at timestamp NOT NULL,
        updated_at timestamp NOT NULL
      );

      CREATE INDEX ON test_events (event_at, name)
    SQL
  end

  after do
    master_connection.tables.sort.reverse.each { |t| master_connection.drop_table(t) }
    master_connection.drop_database("sliding_partition_test")
  end

  let(:connection) { ActiveRecord::Base.connection }
  let(:tables) { connection.tables }

  describe "#initialize!" do
    it "should create the partitioned tables" do
      partition = SlidingPartition::Partition.new(:test_events) do |partition|
        partition.time_column        = :event_at
        partition.suffix             = "%Y%m%d"
        partition.partition_interval = 1.month
        partition.retention_interval = 6.months
      end

      partition.initialize!(time: Time.new(2016, 01, 10))

      %w[
        test_events_20150701
        test_events_20150801
        test_events_20150901
        test_events_20151001
        test_events_20151101
        test_events_20151201
        test_events_20160101
        test_events_20160201
      ].each do |partition|
        expect(tables).to include partition
      end

      expect(tables).to_not include "test_events_20150601"
      expect(tables).to_not include "test_events_20160301"
    end
  end

  describe "#rotate!" do
    let(:partition) do
      SlidingPartition::Partition.new(:test_events) do |partition|
        partition.time_column        = :event_at
        partition.suffix             = "%Y%m%d"
        partition.partition_interval = 1.month
        partition.retention_interval = 6.months
      end
    end

    before do
      partition.initialize!(time: Time.new(2016, 01, 10))
    end

    it "should create the next partition, and drop the previous" do
      expect(tables).to     include("test_events_20150701")
      expect(tables).to_not include("test_events_20160301")

      partition.rotate!(time: Time.new(2016, 02, 10))

      tables = connection.tables # reload the tables

      expect(tables).to_not include("test_events_20150701")
      expect(tables).to     include("test_events_20160301")
    end
  end
end
