
module SlidingPartition
  class PartitionDDLChanger
    extend Forwardable

    attr_reader :definition, :time, :partitions

    delegate %i[ inherited_table_name time_column suffix
                 partition_interval retention_interval ] => :definition

    def initialize(definition, time)
      @definition, @time = definition, time
      @partitions = @definition.partitions(at: time)
    end

    def setup!
      connection.transaction do
        create_tables!
        update_trigger_function!
        create_trigger!
      end
    end

    def rotate!
      connection.transaction do
        create_tables!
        expire_tables!
        update_trigger_function!
      end
    end

    def migrate!
      connection.transaction do
        clone_new_table!
        swap_tables!
        setup!
        migrate_data!(from: retired_table, to: parent_table)
      end
    end

    def create_tables!
      partitions.each do |partition|
        create_partition_table(partition) unless partition_table_exists?(partition)
      end
    end

    def expire_tables!
      candidate_tables.each do |table|
        drop_partition_table(table) unless partitions.map(&:table_name).include?(table)
      end
    end

    def clone_new_table!
      connection.execute <<-SQL
        CREATE TABLE #{new_table} (
          LIKE #{parent_table} INCLUDING ALL
        );
      SQL
    end

    def swap_tables!
      connection.execute <<-SQL
        ALTER TABLE #{parent_table} RENAME TO #{retired_table};
        ALTER TABLE #{new_table} RENAME TO #{parent_table};
      SQL
      create_trigger!
    end

    def migrate_data!(from:, to:)
      partitions.each do |partition|
        connection.execute <<-SQL
        INSERT INTO #{to} (
          SELECT * FROM #{from}
          WHERE #{time_column} >= TIMESTAMP '#{partition.timestamp_floor.to_s(:db)}'
            AND #{time_column} <  TIMESTAMP '#{partition.timestamp_ceiling.to_s(:db)}'
        );
        SQL
      end
    end

    protected

    def create_partition_table(partition)
      connection.execute(create_table_sql(partition))
    end

    def drop_partition_table(table)
      connection.drop_table(table)
    end

    def partition_table_exists?(partition)
      connection.tables.include?(partition.table_name)
    end

    def update_trigger_function!
      connection.execute(trigger_function_sql)
    end

    def create_trigger!
      connection.execute(<<-SQL)
      DROP TRIGGER IF EXISTS #{inherited_table_name}_trigger ON #{inherited_table_name};
      CREATE TRIGGER #{inherited_table_name}_trigger
          BEFORE INSERT ON #{inherited_table_name}
          FOR EACH ROW EXECUTE PROCEDURE #{inherited_table_name}_insert_trigger();
      SQL

    end

    def trigger_function_sql
      conditions = partitions.reverse_each.map do |partition|
        <<-SQL
        ( NEW.#{time_column} >= TIMESTAMP '#{partition.timestamp_floor.to_s(:db)}' AND
          NEW.#{time_column} <  TIMESTAMP '#{partition.timestamp_ceiling.to_s(:db)}'
        ) THEN INSERT INTO #{partition.table_name} VALUES (NEW.*);
        SQL
      end

      <<-SQL
      CREATE OR REPLACE FUNCTION #{inherited_table_name}_insert_trigger()
      RETURNS TRIGGER AS $$
      BEGIN
          IF #{conditions.join("\n ELSIF ")}
          ELSIF (NEW.#{time_column} < TIMESTAMP '#{partitions.first_partition_timestamp.to_s(:db)}')
            THEN RETURN NULL; -- Just discard pre-historic rows
          ELSE
              RAISE EXCEPTION 'Date out of range.  Fix the measurement_insert_trigger() function!';
          END IF;
          RETURN NULL;
      END;
      $$
      LANGUAGE plpgsql;
      SQL
    end

    def create_table_sql(partition)
      <<-SQL
      CREATE TABLE #{partition.table_name} (
        LIKE #{inherited_table_name} INCLUDING ALL
      ) INHERITS (#{inherited_table_name});

      ALTER TABLE #{partition.table_name}
      ADD CHECK (
        #{time_column} >= TIMESTAMP '#{partition.timestamp_floor.to_s(:db)}' AND
        #{time_column} <  TIMESTAMP '#{partition.timestamp_ceiling.to_s(:db)}'
      )
      SQL
    end

    def candidate_tables
      connection.tables.map do |candidate|
        next unless candidate.starts_with?(inherited_table_name.to_s + "_")

        begin
          Time.strptime(candidate, [inherited_table_name, suffix].join("_"))
        rescue ArgumentError
          next
        end

        candidate
      end.compact
    end

    def connection
      definition.model.connection
    end

    def parent_table
      @new_table_name || inherited_table_name
    end

    def new_table
      parent_table + "_new"
    end

    def retired_table
      parent_table + "_retired"
    end

  end
end
