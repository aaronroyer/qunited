module QUnited
  class Runner

    # The drivers in order of which to use first when not otherwise specified
    DRIVERS_PRIORITY = [:PhantomJs, :Rhino].freeze

    attr_accessor :js_source_files, :js_test_files, :options

    def initialize(js_source_files, js_test_files, options={})
      @js_source_files, @js_test_files, @options = js_source_files, js_test_files, options
    end

    def run
      [js_source_files, js_test_files].each { |files| confirm_existence_of_files files }

      driver_class, formatter_class = resolve_driver_class, resolve_formatter_class
      driver = driver_class.new(js_source_files, js_test_files)
      driver.formatter = formatter_class.new({:driver_name => driver.name})

      results = driver.run

      results.all? { |r| r.passed? }
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
      end

      driver_class ||= best_available_driver
      raise(UsageError, 'No driver available') unless driver_class
      driver_class
    end

    def resolve_formatter_class
      if options[:formatter]
        begin
          formatter_class = get_formatter(options[:formatter])
        rescue NameError
          raise UsageError, "#{options[:formatter].to_s} does not exist"
        end

        raise UsageError, "#{formatter_class} formatter not found" unless formatter_class
      end

      formatter_class || ::QUnited::Formatter::Dots
    end

    def get_driver(klass)
      if known_driver_classes.include?(klass)
        ::QUnited::Driver.const_get(klass.to_s)
      end
    end

    def get_formatter(klass)
      if known_formatter_classes.include?(klass)
        ::QUnited::Formatter.const_get(klass.to_s)
      end
    end

    def best_available_driver
      DRIVERS_PRIORITY.map { |driver| get_driver(driver) }.find { |driver| driver.available? }
    end

    def confirm_existence_of_files(files_array)
      files_array.each { |f| raise UsageError, "File not found: #{f}" unless File.exist? f }
    end

    private

    def known_driver_classes
      ::QUnited::Driver.constants.map(&:to_sym).reject { |d| [:Base, :ResultsCollector].include? d }
    end

    def known_formatter_classes
      ::QUnited::Formatter.constants.map(&:to_sym).reject { |d| d == :Base }
    end
  end
end
