require 'tempfile'
require 'fileutils'
require 'open3'

module QUnited
  module Driver
    class Rhino < Base
      SUPPORT_DIR = File.expand_path('../support', __FILE__)

      # Determines whether this driver available to use. Checks whether java
      # is on the PATH and whether Java is version 1.1 or greater.
      def self.available?
        java_exe = which('java')
        if java_exe
          stdin, stdout, stderr = Open3.popen3('java -version')
          begin
            version = Float(stderr.read.split("\n").first[/(\d+\.\d+)/, 1])
            version >= 1.1
          rescue
            false
          end
        end
      end

      def run
        js_jar, runner = File.join(SUPPORT_DIR, 'js.jar'), File.join(SUPPORT_DIR, 'runner.js')

        source_files_args = @source_files.map { |sf| %{"#{sf}"} }.join(' ')
        test_files_args = @test_files.map { |tf| %{"#{tf}"} }.join(' ')

        send_to_formatter(:start)

        cmd = %{java -jar "#{js_jar}" -opt -1 "#{runner}" }
        cmd << %{"#{QUnited::Driver::Base::SUPPORT_DIR}" "#{SUPPORT_DIR}"}
        cmd << " #{source_files_args} -- #{test_files_args}"

        @results = []

        Open3.popen3(cmd) do |stdin, stdout, stderr|
          results_collector = ResultsCollector.new(stdout)
          results_collector.on_test_result do |result|
            @results << result
            method = result.passed? ? :test_passed : :test_failed
            send_to_formatter(method, result)
          end

          results_collector.collect_results

          # Allow stderr to get blasted out to console - if there are uncaught exceptions or
          # anything else that goes wrong with Rhino the user will probably want to know.
          unless (err = stderr.read).strip.empty? then $stderr.puts(err) end
        end

        send_to_formatter(:stop)
        send_to_formatter(:summarize)

        @results
      end
    end
  end
end
