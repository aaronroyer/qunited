module QUnited
  class Runner

    # The drivers in order of which to use first when not otherwise specified
    DRIVERS = [:PhantomJs, :Rhino].map { |driver| ::QUnited::Driver.const_get(driver) }.freeze

    def self.run(js_source_files, js_test_files)
      driver_class = self.best_available_driver
      driver = driver_class.new(js_source_files, js_test_files)

      puts "\n# Running JavaScript tests with #{driver.name}:\n\n"

      results = driver.run
      puts results
      results.to_i
    end

    # Get the runner that we will be using to run the JavaScript tests.
    def self.best_available_driver
      DRIVERS.find { |driver| driver.available? }
    end
  end
end
