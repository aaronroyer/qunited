module QUnited

  # Simple tests results compiler. Takes a raw results hash that was produced by a runner.
  class Results
    class ModuleResults
      def initialize(data)
        @data = data
      end

      def tests
        @tests ||= @data[:tests].map { |test_data| TestResults.new test_data, @data[:name] }
      end
    end

    class TestResults
      def initialize(data, module_name)
        @data, @module_name = data, module_name
      end

      def assertions
        @data[:assertion_data].map do |assertion_data|
          AssertionResults.new assertion_data, @data[:name], @module_name, @data[:file]
        end
      end

      def passed?; result == :passed end
      def failed?; result == :failed end
      def error?; result == :error end

      def result
        @result ||= if assertions.find { |a| a.error? }
          :error
        else
          assertions.find { |a| a.failed? } ? :failed : :passed
        end
      end

      def to_s; passed? ? '.' : (error? ? 'E' : 'F') end
    end

    class AssertionResults
      def initialize(data, test_name, module_name, file)
        @data, @test_name, @module_name, @file = data, test_name, module_name, file
      end

      def message
        @data[:message]
      end

      def result
        if @data[:result]
          :passed
        else
          @data[:message] =~ /^Died on test/ ? :error : :failed
        end
      end

      def passed?; result == :passed end
      def failed?; result == :failed end
      def error?; result == :error end

      def output(count)
        return "" if passed?
        msg = "  " + (count ? "#{count.to_s}) " : "")
        msg << "#{error? ? 'Error' : 'Failure'}:\n"
        msg << "#{@test_name} (#{@module_name}) [#{@file}]\n"
        msg << "#{@data[:message] || 'Failed assertion, no message given.'}\n"

        # Results can be nil. Also, JavaScript nulls will be converted, by the YAML serializer, to
        # Ruby nil. Convert that back to 'null' for the output.
        if @data.key? :expected
          expected, actual = @data[:expected], @data[:actual]
          msg << "Expected: #{expected.nil? ? 'null' : expected.inspect}\n"
          msg <<   "  Actual: #{actual.nil? ? 'null' : actual.inspect}\n"
        end
        msg
      end
    end

    def initialize(modules_results_array)
      @data = modules_results_array.freeze
      @module_results = @data.map { |module_data| ModuleResults.new module_data }
    end

    def to_s
      all_output = dots
      all_output << "\n\n#{failures_output}" unless failures_output.empty?
      all_output << "\n\n#{bottom_line}"
      all_output
    end

    def to_i
      passed? ? 0 : 1
    end

    def passed?
      total_failures.zero? && total_errors.zero?
    end

    def failed?
      !passed?
    end

    def dots
      tests.map { |test| test.to_s }.join
    end

    def bottom_line
      "#{total_tests} tests, #{total_assertions} assertions, " +
      "#{total_failures} failures, #{total_errors} errors, 0 skips"
    end

    def failures_output
      failures_output_array.join("\n")
    end

    # Array of failure output block strings
    def failures_output_array
      return @failures_output_array if @failures_output_array
      count = 0
      @failures_output_array = (failures + errors).map { |failure| failure.output(count += 1) }
    end

    # Other data compilation methods

    def total_tests
      @total_tests ||= @module_results.inject(0) { |count, mod| count += mod.tests.size }
    end

    def total_assertions; assertions.size end
    def total_failures; failures.size end
    def total_errors; errors.size end

    private

    def tests
      @tests ||= @module_results.inject([]) { |tests, mod| tests += mod.tests }
    end

    def assertions
      @assertions ||= tests.inject([]) { |asserts, test| asserts += test.assertions }
    end

    def failures
      @failures ||= assertions.select { |assert| assert.failed? }
    end

    def errors
      @errors ||= assertions.select { |assert| assert.error? }
    end
  end
end
