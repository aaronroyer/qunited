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

        results_file = Tempfile.new('qunited_results')
        results_file.close

        cmd = %{java -jar "#{js_jar}" -opt -1 "#{runner}" }
        cmd << %{"#{QUnited::Driver::Base::SUPPORT_DIR}" "#{SUPPORT_DIR}" "#{results_file.path}"}
        cmd << " #{source_files_args} -- #{test_files_args}"

        # Swallow stdout but allow stderr to get blasted out to console - if there are uncaught
        # exceptions or anything else that goes wrong with the JavaScript interpreter the user
        # will probably want to know but we are not particularly interested in it.
        Open3.popen3(cmd) do |stdin, stdout, stderr|
          stdout.each {||} # Ignore; this is just here to make sure we block
                           # while waiting for tests to finish
          unless (err = stderr.read).strip.empty? then $stderr.puts(err) end
        end

        @results = ::QUnited::Results.from_javascript_produced_json(IO.read(results_file.path))
      end
    end
  end
end
