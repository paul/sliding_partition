# frozen_string_literal: true

require "sliding_partition/identity"
require "sliding_partition/definition"

require "sliding_partition/engine" if defined?(Rails)

module SlidingPartition

  def self.define(model, &config)
    parititions << Definition.new(model, &config)
  end

  def self.setup!
    parititions.each { |p| p.setup! }
  end

  def self.parititions
    @@parititions ||= []
  end

end
