require 'optparse'
require 'ostruct'

module QUnited
  class Application
    def run
      handle_exceptions do
        handle_options
        run_tests
      end
    end

    def run_tests
      js_source_files, js_test_files = ARGV.join(' ').split('--').map { |file_list| file_list.split(' ') }
      exit QUnited::Runner.new(js_source_files, js_test_files, options).run
    end

    # Client options generally parsed from the command line
    def options
      @options ||= {}
    end

    # Parse and handle command line options
    def handle_options
      drivers = ::QUnited::Driver.constants.reject { |d| d == :Base }
      valid_drivers_string = "Valid drivers include: #{drivers.map { |d| d.to_s }.join(', ')}"

      args_empty = ARGV.empty?

      # This is a bit of a hack, but OptionParser removes the -- that separates the source
      # and test files and we need to put it back in the right place. Save the distance from
      # the end to do this later.
      double_dash_neg_index = ARGV.find_index('--') && (ARGV.find_index('--') - ARGV.size)

      optparse = OptionParser.new do |opts|
        opts.banner = <<-HELP_TEXT
Usage: qunited [OPTIONS] [JS_SOURCE_FILES...] -- [JS_TEST_FILES..]

Runs JavaScript unit tests with QUnit.

JS_SOURCE_FILES are the JavaScript files that you want to test. They will all be
loaded for running each test.

JS_TEST_FILES are files that contain the QUnit tests to run.

Options:
        HELP_TEXT

        opts.on('-d', '--driver [NAME]', 'Specify the driver to use in running the tests',
            valid_drivers_string) do |name|
          raise UsageError, 'Must specify a driver name with -d or --driver option' unless name
          names_and_drivers = Hash[drivers.map { |d| d.to_s.downcase }.zip(drivers)]
          driver = names_and_drivers[name.downcase]
          raise UsageError, "Invalid driver specified: #{name}\n#{valid_drivers_string}" unless driver
          options[:driver] = driver
        end
        opts.on_tail('-h', '--help', 'Show this message') do
          puts opts
          exit
        end
        opts.on_tail('--version', 'Print the QUnited version') do
          puts ::QUnited::VERSION
          exit
        end

        if args_empty
          puts opts
          exit 1
        end
      end.parse!

      # Put the -- back in if we had one initially and it was removed
      if double_dash_neg_index && !ARGV.include?('--')
        ARGV.insert(double_dash_neg_index, '--')
      end
    end

    private

    def handle_exceptions
      begin
        yield
      rescue SystemExit
        exit
      rescue UsageError => ex
        $stderr.puts ex.message
        exit 1
      rescue OptionParser::InvalidOption => ex
        $stderr.puts ex.message
        exit 1
      rescue Exception => ex
        display_error_message ex
        exit 1
      end
    end

    def display_error_message(ex)
      msg = <<MSG
QUnited has aborted! If this is unexpected, you may want to open an issue at
github.com/aaronroyer/qunited to get a possible bug fixed. If you do, please
include the debug information below.
MSG
      $stderr.puts msg
      $stderr.puts ex.message
      $stderr.puts ex.backtrace
    end
  end
end
