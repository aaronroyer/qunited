require 'pathname'
require 'tempfile'
require 'fileutils'
require 'erb'
require 'open3'

module QUnited
  module Driver
    class PhantomJs < Base
      SUPPORT_DIR = File.expand_path('../support', __FILE__)

      # Determines whether this driver available to use.
      # Checks whether phantomjs is on the PATH.
      def self.available?
        !!which('phantomjs')
      end

      def name
        'PhantomJS'
      end

      def run
        self.tests_file = Tempfile.new(['tests_page', '.html'])
        tests_file.write(tests_page_content)
        tests_file.close

        send_to_formatter(:start)

        cmd = %|phantomjs "#{File.join(SUPPORT_DIR, 'runner.js')}" "#{tests_file.path}"|

        @results = []

        Open3.popen3(cmd) do |stdin, stdout, stderr|
          results_collector = ResultsCollector.new(stdout)

          results_collector.on_test_result do |result|
            @results << result
            method = result.passed? ? :test_passed : :test_failed
            send_to_formatter(method, result)
          end

          results_collector.on_non_test_result_line do |line|
            # PhantomJS sometimes puts error messages to stdout. If we are not reading
            # a test result then redirect any output to stderr
            $stderr.puts(line)
          end

          results_collector.collect_results

          err = stderr.read
          unless err.nil? || err.strip.empty? then $stderr.puts(err) end
        end

        send_to_formatter(:stop)
        send_to_formatter(:summarize)

        @results
      end

      private

      attr_accessor :tests_file

      def tests_page_content
        ERB.new(IO.read(File.join(SUPPORT_DIR, 'tests_page.html.erb'))).result(binding)
      end

      def script_tag(file)
        js_file_path, tests_file_path = Pathname.new(file).realpath, Pathname.new(tests_file.path)
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
