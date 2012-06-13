module QUnited

  # Simple tests results compiler. Takes a raw results hash that was produced a runner.
  class Results
    def initialize(modules_results_array)
      @data = modules_results_array
    end

    def total_tests
      tests.size
    end

    def total_assertions
      tests.inject(0) { |asserts, test| asserts += test[:assertions] }
    end

    def total_failures
      tests.inject(0) { |fails, test| fails += test[:failed] }
    end

    private

    def modules
      @data
    end

    def tests
      @tests ||= modules.inject([]) { |tests, mod| tests += mod[:tests] }
    end
  end
end
