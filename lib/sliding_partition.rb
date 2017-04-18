# frozen_string_literal: true

require "sliding_partition/identity"
require "sliding_partition/definition"

require "sliding_partition/railtie" if defined?(Rails)

module SlidingPartition

  def self.define(model, &config)
    parititions[model] = Definition.new(model, &config)
  end

  def self.setup!
    parititions.values.each { |p| p.setup! }
  end

  def self.rotate!
    parititions.values.each { |p| p.rotate! }
  end

  def self.migrate!
    parititions.values.each { |p| p.migrate! }
  end

  def self.final_copy!
    parititions.values.each { |p| p.final_copy! }
  end

  def self.parititions
    @@parititions ||= {}
  end

end
