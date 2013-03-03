module QUnited
  module Formatter
    class Dots < Base
      def start
        super
        output.print "\n# Running JavaScript tests with #{driver_name}:\n\n"
      end

      def test_passed(result)
        super result
        output.print '.'
      end

      def test_failed(result)
        super result
        output.print(result.error? ? 'E' : 'F')
      end

      def summarize
        output.print "\n\n#{times_line}\n"
        output.print failure_output
        output.print "\n#{bottom_line}\n"
      end

      private

      def failure_output
        return '' unless total_failures > 0

        all_failure_output = ''
        count = 1
        failures.each do |test|
          test.assertions.reject { |a| a.passed? }.each do |assertion|
            file_name_output = (test.file && !test.file.strip.empty?) ? " [#{test.file}]" : ''
            msg = "\n  " + (count ? "#{count.to_s}) " : "")
            msg << "#{assertion.error? ? 'Error' : 'Failure'}:\n"
            msg << "#{test.name} (#{test.module_name})#{file_name_output}\n"
            msg << "#{assertion.message || 'Failed assertion, no message given.'}\n"

            if assertion.data.key? :expected
              msg << "Expected: #{assertion.expected.nil? ? 'null' : assertion.expected.inspect}\n"
              msg << "  Actual: #{assertion.actual.nil? ? 'null' : assertion.actual.inspect}\n"
            end
            all_failure_output << msg
            count += 1
          end
        end

        all_failure_output
      end

      def times_line
        total_time = test_results.inject(0) { |total, result| total += result.duration }

        tests_per = (total_time > 0) ? (total_tests / total_time) : total_tests
        assertions_per = (total_time > 0) ? (total_assertions / total_time) : total_assertions

        "Finished in #{"%.6g" % total_time} seconds, #{"%.6g" % tests_per} tests/s, " +
          "#{"%.6g" % assertions_per} assertions/s."
      end

      def bottom_line
        "#{total_tests} tests, #{total_assertions} assertions, " +
          "#{total_failures} failures, #{total_errors} errors"
      end

      def failures
        test_results.select { |tr| tr.failed? }
      end

      def total_tests
        test_results.size
      end

      # Test failures, not assertion failures
      def total_failures
        failures.size
      end

      # Test errors, not assertion errors
      def total_errors
        test_results.select { |tr| tr.error? }.size
      end

      def total_assertions
        test_results.inject(0) { |total, result| total += result.assertions.size}
      end
    end
  end
end
