module QUnited

  # Simple tests results compiler. Takes a raw results hash that was produced by a runner.
  class Results
    def initialize(modules_results_array)
      @data = modules_results_array
      @data.freeze
    end

    # Results output methods

    def dots
      tests.map { |test| test[:failed] > 0 ? 'F' : '.' }.join
    end

    def bottom_line
      "#{total_tests} tests, #{total_assertions} assertions, #{total_failures} failures, 0 errors, 0 skips"
    end

    def failures_output_array
      failures_output = []
      failures.each_with_index do |failure, i|
        out =  "  #{i+1}) Failure:\n"
        out << "#{failure[:test_name]} (#{failure[:module_name]}) [#{failure[:file]}]\n"
        out << "#{failure[:message] || 'Failed assertion, no message given.'}"
        if failure[:expected]
          out << "\nExpected: #{failure[:expected]}\n"
          out <<   "  Actual: #{failure[:actual]}\n"
        end

        failures_output << out
      end
      failures_output
    end

    # Other data compilation methods

    def total_tests
      tests.size
    end

    def total_assertions
      tests.inject(0) { |asserts, test| asserts += test[:assertions] }
    end

    def total_failures
      tests.inject(0) { |fails, test| fails += test[:failed] }
    end

    def raw_results
      @data
    end

    private

    def modules
      @data
    end

    def tests
      @tests ||= modules.inject([]) do |tests, mod|
        tests += mod[:tests].map do |test_data|
          # Add module name for convenience in writing results
          test_data[:module_name] = mod[:name]
          test_data
        end
      end
    end

    def assertions
      @assertions ||= tests.inject([]) do |asserts, test|
        asserts += test[:assertion_data].map do |assertion_data|
          # Add test, module, and file name for convenience in writing results
          assertion_data[:test_name] = test[:name]
          assertion_data[:module_name] = test[:module_name]
          assertion_data[:file] = test[:file]
          assertion_data
        end
      end
    end

    def failures
      @failures ||= assertions.select { |assert| !assert[:result] }
    end
  end
end
