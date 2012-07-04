require 'tempfile'
require 'fileutils'
require 'yaml'
require 'open3'

module QUnited
  module Driver
    class Rhino < Base
      def can_run?
        # TODO: test that you have Java
      end

      def run
        support_dir = File.expand_path('../support', __FILE__)
        js_jar, runner = File.join(support_dir, 'js.jar'), File.join(support_dir, 'runner.js')

        source_files_args = @source_files.map { |sf| %{"#{sf}"} }.join(' ')
        test_files_args = @test_files.map { |tf| %{"#{tf}"} }.join(' ')

        tmp_file = Tempfile.new('qunited_results')
        tmp_file.close

        cmd = %{java -jar "#{js_jar}" -opt -1 "#{runner}" }
        cmd << %{"#{QUnited::Driver::Base.support_dir}" "#{support_dir}" "#{tmp_file.path}"}
        cmd << " #{source_files_args} -- #{test_files_args}"

        # Swallow stdout but allow stderr to get blasted out to console - if there are uncaught
        # exceptions or anything else that goes wrong with the JavaScript interpreter the user
        # will probably want to know but we are not particularly interested in it.
        Open3.popen3(cmd) do |stdin, stdout, stderr|
          stdout.each {||} # Ignore; this is just here to make sure we block
                           # while waiting for tests to finish
          unless (err = stderr.read).strip.empty? then $stderr.puts(err) end
        end

        @raw_results = clean_up_results(YAML.load(IO.read(tmp_file)))

        @results = ::QUnited::Results.new @raw_results
      end
    end
  end
end
