module QUnited
  class RakeTask < ::Rake::TaskLib
    include ::Rake::DSL if defined?(::Rake::DSL)

    # Name of task.
    #
    # default:
    #   :qunited
    attr_accessor :name

    # Glob pattern to match JavaScript source files (and any dependencies). Note that the
    # order will be indeterminate so if your JavaScript files must be included in a particular
    # order you will have to use source_files=(files_array).
    #
    # If an array of files is set with source_files=(files_array) then this will be ignored.
    attr_accessor :source_files_pattern

    # Array of JavaScript source files (and any dependencies). These will be loaded in order
    # before loading the QUnit tests.
    attr_accessor :source_files

    # Glob pattern to match QUnit test files.
    #
    # If an array of test files is set with test_files=(files) then this will be ignored.
    attr_accessor :test_files_pattern

    # Array of QUnit test files.
    attr_accessor :test_files

    # The driver to use to run the QUnit tests.
    attr_accessor :driver

    # Use verbose output. If this is true, the task will print the QUnited command to stdout.
    #
    # default:
    #   true
    attr_accessor :verbose

    def initialize(*args)
      @name = args.shift || :qunited
      @verbose = true

      yield self if block_given?

      desc('Run QUnit JavaScript tests') unless ::Rake.application.last_comment

      task name do
        RakeFileUtils.send(:verbose, verbose) do
          if source_files_to_include.empty?
            msg = "No JavaScript source files specified"
            msg << " with pattern #{source_files_pattern}" if source_files_pattern
            puts msg
          elsif test_files_to_run.empty?
            puts "No QUnit test files matching #{test_files_pattern} could be found"
          else
            begin
              puts command if verbose
              success = system(command)
            rescue
            end
            raise "#{command} failed" unless success
          end
        end
      end
    end

    private

    def command
      cmd = 'qunited'
      cmd << " --driver #{driver}" if driver
      cmd << " #{source_files_to_include.join(' ')} -- #{test_files_to_run.join(' ')}"
    end

    def source_files_to_include
      source_files || pattern_to_filelist(source_files_pattern)
    end

    def test_files_to_run
      test_files || pattern_to_filelist(test_files_pattern)
    end

    def pattern_to_filelist(pattern)
      FileList[pattern].map { |f| f.gsub(/"/, '\"').gsub(/'/, "\\\\'") }
    end
  end
end
