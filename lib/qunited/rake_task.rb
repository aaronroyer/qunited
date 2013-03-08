module QUnited
  class RakeTask < ::Rake::TaskLib
    include ::Rake::DSL if defined?(::Rake::DSL)

    # Name of task.
    #
    # default:
    #   :qunited
    attr_accessor :name

    # <b>DEPRECATED:</b> Please use <tt>source_files=</tt>, which now takes either an array of files
    # or a glob pattern string.
    def source_files_pattern=(pattern)
      warn 'source_files_pattern= is deprecated in QUnited rake task config, use source_files= with a pattern'
      @source_files = pattern
    end

    # Array of JavaScript source files (and any dependencies). These will be loaded in order
    # before loading the QUnit tests.
    attr_accessor :source_files

    # <b>DEPRECATED:</b> Please use <tt>test_files=</tt>, which now takes either an array of files
    # or a glob pattern string.
    def test_files_pattern=(pattern)
      warn 'test_files_pattern= is deprecated in QUnited rake task config, use test_files= with a pattern'
      @test_files = pattern
    end

    # Array of QUnit test files.
    attr_accessor :test_files

    # The driver to use to run the QUnit tests.
    attr_accessor :driver

    # Use verbose output. If this is true, the task will print the QUnited command to stdout.
    #
    # default:
    #   true
    attr_accessor :verbose

    # Fail rake task when tests fail.
    #
    # default:
    #   true
    attr_accessor :fail_on_test_failure

    # The port to use if running the server.
    #
    # default:
    #   3040
    attr_accessor :server_port

    def initialize(*args)
      @name = args.shift || :qunited
      @verbose = true
      @fail_on_test_failure = true
      @server_port = nil

      yield self if block_given?

      desc('Run QUnit JavaScript tests') unless ::Rake.application.last_comment

      task name do
        RakeFileUtils.send(:verbose, verbose) do
          if source_files_to_include.empty?
            msg = if source_files.is_a? String
              "No JavaScript source files match the pattern '#{source_files}'"
            else
              'No JavaScript source files specified'
            end
            fail msg
          elsif test_files_to_run.empty?
            msg = if test_files.is_a? String
              "No QUnit test files match the pattern '#{test_files}'"
            else
              'No QUnit test files specified'
            end
            fail msg
          else
            command = test_command
            puts command if verbose
            success = system(command)

            unless success
              if $?.exitstatus == 10
                # 10 is our test failure status code
                fail 'QUnit tests failed' if @fail_on_test_failure
              else
                # Other status codes should mean unexpected crashes
                fail 'Something went wrong when running tests with QUnited'
              end
            end
          end
        end
      end

      desc('Run server for QUnit JavaScript tests')

      task (name.to_s + ':server') do
        require 'qunited/server'
        server_options = {
          :source_files => source_files_to_include,
          :test_files => test_files_to_run
        }
        server_options[:port] = @server_port if @server_port
        ::QUnited::Server.new(server_options).start
      end
    end

    private

    def test_command
      cmd = 'qunited'
      cmd << " --driver #{driver}" if driver
      cmd << " #{source_files_to_include.join(' ')} -- #{test_files_to_run.join(' ')}"
    end

    def source_files_to_include
      files_array source_files
    end

    def test_files_to_run
      files_array test_files
    end

    # Force convert to array of files if glob pattern
    def files_array(files)
      return [] unless files
      files.is_a?(Array) ? files : pattern_to_filelist(files.to_s)
    end

    def pattern_to_filelist(pattern)
      FileList[pattern].map { |f| f.gsub(/"/, '\"').gsub(/'/, "\\\\'") }
    end
  end
end
