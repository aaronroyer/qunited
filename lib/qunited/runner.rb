module QUnited
  class Runner
    def self.run(js_source_files, js_test_files)
      js_runner_klass = self.js_runner
      # TODO: test that this JsRunner can run with current environment
      runner = js_runner_klass.new(js_source_files, js_test_files)

      puts "\nRunning JavaScript tests with #{runner.name}\n\n"

      results = runner.run.results
      puts results
      results.to_i
    end

    # Get the runner that we will be using to run the JavaScript tests.
    #
    # Right now we only have one JavaScript runner, but when we have multiple we will have to
    # determine which one we will used unless explicitly configured.
    def self.js_runner
      ::QUnited::JsRunner::Rhino
    end
  end
end
