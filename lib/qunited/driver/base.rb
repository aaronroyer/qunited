require 'tempfile'

module QUnited
  module Driver
    class Base
      # Path of the common (to all drivers) supporting files directory
      SUPPORT_DIR = File.expand_path('../support', __FILE__)

      TEST_RESULT_START_TOKEN = 'QUNITED_TEST_RESULT_START_TOKEN'
      TEST_RESULT_END_TOKEN   = 'QUNITED_TEST_RESULT_END_TOKEN'
      TEST_RESULT_REGEX       = /#{TEST_RESULT_START_TOKEN}(.*?)#{TEST_RESULT_END_TOKEN}/m

      COFFEESCRIPT_EXTENSIONS = ['coffee', 'cs']

      attr_reader :results, :source_files, :test_files
      attr_accessor :formatter, :fixture_files

      # Finds an executable on the PATH. Returns the absolute path of the
      # executable if found, otherwise nil.
      def self.which(cmd)
        exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
        ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
          exts.each do |ext|
            exe = "#{path}/#{cmd}#{ext}"
            return exe if File.executable? exe
          end
        end
        return nil
      end

      # Overridden in subclasses to return true if the underlying library is installed
      def self.available?
        false
      end

      # Initialize the driver with source and test files. The files can be described either with
      # glob patterns or arrays of file names.
      def initialize(source_files, test_files)
        @source_files = normalize_files source_files
        @test_files = normalize_files test_files
        @fixture_files = []
      end

      def command
        raise 'not implemented'
      end

      def run
        @tests_file = Tempfile.new(['tests_page', '.html'])
        @tests_file.write(tests_page_content)
        @tests_file.close
        puts @tests_file.path

        send_to_formatter(:start)

        @results = []

        Open3.popen3(command) do |stdin, stdout, stderr|
          results_collector = ResultsCollector.new(stdout)

          results_collector.on_test_result do |result|
            @results << result
            method = result.passed? ? :test_passed : :test_failed
            send_to_formatter(method, result)
          end

          results_collector.on_non_test_result_line do |line|
            # Drivers sometimes print error messages to stdout. If we are not reading
            # a test result then redirect any output to stderr
            $stderr.puts(line)
          end

          results_collector.collect_results

          err = stderr.read
          $stderr.puts(err) if err && !err.empty?
        end

        send_to_formatter(:stop)
        send_to_formatter(:summarize)

        @results
      end

      def support_file_path(filename)
        File.join(SUPPORT_DIR, filename)
      end

      def support_file_contents(filename)
        IO.read(support_file_path(filename))
      end

      def name
        self.class.name.split('::')[-1]
      end

      private

      def send_to_formatter(method, *args)
        formatter.send(method, *args) if formatter
      end

      # Hash that maps CoffeeScript file paths to temporary compiled JavaScript files. This is
      # used partially because we need to keep around references to the temporary files or else
      # they could be deleted.
      def compiled_coffeescript_files
        @compiled_coffeescript_files ||= {}
      end

      # Produces an array of JavaScript filenames from either a glob pattern or an array of
      # JavaScript or CoffeeScript filenames. Files with CoffeeScript extensions will be
      # compiled and replaced in the produced array with temp files of compiled JavaScript.
      def normalize_files(files)
        files = Dir.glob(files) if files.is_a? String

        files.map do |file|
          if COFFEESCRIPT_EXTENSIONS.include? File.extname(file).sub(/^\./, '')
            compile_coffeescript file
          else
            file
          end
        end
      end

      # Compile the CoffeeScript file with the given filename to JavaScript. Returns the full
      # path of the compiled JavaScript file. The file is created in a temporary directory.
      def compile_coffeescript(file)
        begin
          require 'coffee-script'
        rescue LoadError
          msg = <<-ERROR_MSG
You must install an additional gem to use CoffeeScript source or test files.
Run the following command (with sudo if necessary): gem install coffee-script
          ERROR_MSG
          raise UsageError, msg
        end

        compiled_js_file = Tempfile.new(["compiled_#{File.basename(file).gsub('.', '_')}", '.js'])
        compiled_js_file.write CoffeeScript.compile(File.read(file))
        compiled_js_file.close

        compiled_coffeescript_files[file] = compiled_js_file

        compiled_js_file.path
      end

      def tests_page_content
        ERB.new(IO.read(support_file_path('tests_page.html.erb'))).result(binding)
      end

      def read_file(file)
        IO.read(file)
      end

      def script_tag(file)
        js_file_path, tests_file_path = Pathname.new(file).realpath, Pathname.new(@tests_file.path)
        begin
          rel_path = js_file_path.relative_path_from(tests_file_path)
          # Attempt to convert paths to relative URLs if Windows... should really test this
          return %{<script type="text/javascript" src="#{rel_path.to_s.gsub(/\\/, '/')}"></script>}
        rescue ArgumentError
          # If we cannot get a relative path to the js file then just put the contents
          # of the file inline. This can happen for a few reasons, like if the drive
          # letter is different on Windows.
          return <<-SCRIPT_ELEMENT
<script type="text/javascript">
  #{IO.read(file)}
</script>
          SCRIPT_ELEMENT
        end
      end
    end
  end
end
