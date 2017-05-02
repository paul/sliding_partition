require "spec_helper"

require "active_record"

RSpec.describe "Migrating data" do

  Event = Class.new(ActiveRecord::Base)
  before :all do
    ENV["TZ"] = "UTC"
    ActiveRecord::Base.establish_connection(adapter: "postgresql", database: "sliding_partition_test")
    ActiveRecord::Base.logger = Logger.new("log/test.log")
    ActiveRecord::Base.connection.execute(<<-SQL)
      DROP TABLE IF EXISTS events;
      CREATE TABLE events (
        id serial primary key,
        event_at timestamp NOT NULL,
        data text NOT NULL
      )
    SQL
  end

  around do |example|
    ActiveRecord::Base.logger.debug "\n"
    ActiveRecord::Base.logger.debug example.metadata[:full_description]

    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end

  let(:connection) { ActiveRecord::Base.connection }
  let(:timestamp) { Time.new(2017, 06, 10) }
  let(:tables) { connection.tables.select { |t| t =~ /^events_\d+$/ }.sort }

  let(:expired_row) { {event_at: timestamp - 12.months, data: "expired" } }
  let(:early_row)   { {event_at: timestamp -  6.months, data: "early"   } }
  let(:late_row)    { {event_at: timestamp            , data: "late"    } }

  before do
    [expired_row, early_row, late_row].each { |row| Event.create!(row) }
    definition.migrate!(at: timestamp, quiet: true)
  end

  context "with a retention interval" do
    let(:definition) do
      SlidingPartition.define(Event) do |partition|
        partition.time_column        = :event_at
        partition.suffix             = "%Y%m%d"
        partition.partition_interval = 1.month
        partition.retention_interval = 6.months
      end
    end

    it "should create a table for each partition in the retention interval" do
      expect(tables.size).to eq(8)
      expect(tables.first).to eq "events_20161201"
      expect(tables.last).to eq "events_20170701"
    end

    it "should copy the rows to the appropriate tables" do
      expect(Event.where(data: "early")).to be_present
      expect(Event.where(data: "late")).to be_present
    end

    it "should discard any rows from before the retention cutoff" do
      expect(Event.where(data: "expired")).to_not be_present
    end

  end

  context "with a rentention interval of :forever" do
    let(:definition) do
      SlidingPartition.define(Event) do |partition|
        partition.time_column        = :event_at
        partition.suffix             = "%Y%m%d"
        partition.partition_interval = 1.month
        partition.retention_interval = :forever
      end
    end

    it "should create tables back to the earliest row" do
      expect(tables.size).to eq(14)
      expect(tables.first).to eq "events_20160601"
      expect(tables.last).to eq "events_20170701"
    end

  end

end


