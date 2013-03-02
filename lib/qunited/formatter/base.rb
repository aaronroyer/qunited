module QUnited
  module Formatter
    class Base
      attr_reader :driver_name, :output, :test_results

      def initialize(options={})
        @driver_name = options[:driver_name]
        @output = options[:output] || $stdout
        @test_results = []
      end

      # Called before we start running tests
      def start
      end

      def test_passed(result)
        @test_results << result
      end

      def test_failed(result)
        @test_results << result
      end

      # Send arbitrary messages to the output stream
      def message
        output.puts message
      end

      # Called after all tests have run, before we summarize results
      def stop
      end

      # Called after we have stopped running tests
      def summarize
      end

      def close
        output.close if IO === output && output != $stdout
      end
    end
  end
end
