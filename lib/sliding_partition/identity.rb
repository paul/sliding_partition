# frozen_string_literal: true

module SlidingPartition
  # Gem identity information.
  module Identity
    def self.name
      "sliding_partition"
    end

    def self.label
      "SlidingPartition"
    end

    def self.version
      "0.2.0"
    end

    def self.version_label
      "#{label} #{version}"
    end
  end
end
