module QUnited
=begin

Run options: --seed 37076

# Running tests:

...FF.

Finished tests in 7.689742s, 0.3901 tests/s, 1.3004 assertions/s.

  1) Failure:
test_failures_are_recorded_correctly(TestRhinoRunner) [/Users/aaron/Dropbox/home/projects/pro/qunited/test/unit/test_rhino_runner.rb:34]:
Correct number of failures given.
Expected: 2
  Actual: 4

  2) Failure:
test_other(TestRhinoRunner) [/Users/aaron/Dropbox/home/projects/pro/qunited/test/unit/test_rhino_runner.rb:38]:
Failed assertion, no message given.

3 tests, 10 assertions, 2 failures, 0 errors, 0 skips
rake aborted!
Command failed with status (1): [/Users/aaron/.rbenv/versions/1.9.3-p0/bin/...]

Tasks: TOP => default => test
(See full trace by running task with --trace)
=end

  # Simple tests results compiler. Takes a raw results hash that was produced by a runner.
  class Results
    def initialize(modules_results_array)
      @data = modules_results_array
      @data.freeze
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

    def raw_results
      @data
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
