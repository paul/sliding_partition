# frozen_string_literal: true

require "spec_helper"
ENV["TZ"] = "UTC"

require "active_record"
require "awesome_print"

RSpec.describe "SlidingPartition" do

  Master = Class.new(ActiveRecord::Base)

  TestEvent = Class.new(ActiveRecord::Base)

  let(:master_connection) do
    Master.establish_connection connection_config.merge(database: "postgres", schema_search_path: "public")
    Master.connection
  end

  let(:connection) do
    ActiveRecord::Base.establish_connection(connection_config)
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

        created_at timestamp NOT NULL DEFAULT NOW(),
        updated_at timestamp NOT NULL DEFAULT NOW()
      );

      CREATE INDEX ON test_events (event_at, name)
    SQL
  end

  after do
    connection.tables.sort.reverse.each { |t| connection.drop_table(t) }
    connection.disconnect!
    master_connection.drop_database("sliding_partition_test")
  end

  let(:tables) { connection.tables }

  let(:definition) do
    SlidingPartition::Definition.new(TestEvent) do |config|
      config.time_column        = :event_at
      config.suffix             = "%Y%m%d"
      config.partition_interval = 1.month
      config.retention_interval = 6.months
    end
  end

  describe "setting up initial tables" do
    it "should create the partitioned tables" do
      definition.setup!(at: Time.new(2016, 01, 10))

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

  describe "rotating the partition tables" do
    before do
      definition.setup!(at: Time.new(2016, 01, 10))
    end

    it "should create the next partition, and drop the previous" do
      expect(tables).to     include("test_events_20150701")
      expect(tables).to_not include("test_events_20160301")

      definition.rotate!(at: Time.new(2016, 02, 10))

      tables = connection.tables # reload the tables

      expect(tables).to_not include("test_events_20150701")
      expect(tables).to     include("test_events_20160301")
    end
  end

  describe "inserting data" do
    before do
      definition.setup!(at: Time.new(2016, 01, 10))
    end

    def insert(timestamp)
      connection.insert <<-SQL
        INSERT INTO test_events (name, event_at, result)
        VALUES ('test', '#{timestamp.to_s(:db)}', 'success')
      SQL
    end

    it "should put it into the right table" do
      insert(Time.new(2016, 1, 20))
      insert(Time.new(2016, 2, 20))

      expect(
        connection.select_value("SELECT COUNT(*) FROM test_events")
      ).to eq 2

      expect(
        connection.select_value("SELECT COUNT(*) FROM test_events_20160101")
      ).to eq 1

      expect(
        connection.select_value("SELECT COUNT(*) FROM test_events_20160201")
      ).to eq 1

    end
  end
end
