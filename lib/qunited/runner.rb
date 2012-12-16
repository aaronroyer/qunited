module QUnited
  class Runner

    # The drivers in order of which to use first when not otherwise specified
    DRIVERS_PRIORITY = [:PhantomJs, :Rhino].freeze

    attr_accessor :js_source_files, :js_test_files, :options

    def initialize(js_source_files, js_test_files, options={})
      @js_source_files, @js_test_files, @options = js_source_files, js_test_files, options
    end

    def run
      driver_class = resolve_driver_class
      driver = driver_class.new(js_source_files, js_test_files)

      puts "\n# Running JavaScript tests with #{driver.name}:\n\n"

      results = driver.run
      puts results
      results.to_i
    end

    def resolve_driver_class
      if options[:driver]
        begin
          driver_class = get_driver(options[:driver])
        rescue NameError
          raise UsageError, "#{options[:driver].to_s} does not exist"
        end

        if !driver_class
          raise UsageError, "#{driver_class} driver not found"
        elsif !driver_class.available?
          raise UsageError, "#{driver_class} driver specified, but not available"
        end
        driver_class
      end

      driver_class ||= best_available_driver
      raise(UsageError, 'No driver available') unless driver_class
      driver_class
    end

    def get_driver(klass)
      if ::QUnited::Driver.constants.reject { |d| d == :Base }.include?(klass.to_s)
        ::QUnited::Driver.const_get(klass.to_s)
      end
    end

    # Get the runner that we will be using to run the JavaScript tests.
    def best_available_driver
      DRIVERS_PRIORITY.map { |driver| get_driver(driver) }.find { |driver| driver.available? }
    end
  end
end
