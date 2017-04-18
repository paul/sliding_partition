
module SlidingPartition
  module Util

    def say_with_time(message)
      say(message)
      result = nil
      time = Benchmark.measure { yield }
      say "%.4fs" % time.real, :subitem
      result
    end

    def say(message, subitem=false)
      puts "#{subitem ? "   ->" : "--"} #{message}" unless @quiet
    end

  end
end
