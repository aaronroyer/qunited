require 'pathname'
require 'tempfile'
require 'fileutils'
require 'erb'
require 'open3'

module QUnited
  module Driver
    class PhantomJs < Base
      def self.available?
        !!which('phantomjs')
      end

      def name
        "PhantomJS" # Slightly more accurate than our class name
      end

      def run
        self.tests_file = Tempfile.new(['tests_page', '.html'])
        tests_file.write(tests_page_content)
        tests_file.close

        results_file = Tempfile.new('qunited_results')
        results_file.close

        cmd = %{phantomjs "#{File.expand_path('../support/runner.js', __FILE__)}" }
        cmd << %{#{tests_file.path} #{results_file.path}}

        Open3.popen3(cmd) do |stdin, stdout, stderr|
          # PhantomJS sometimes puts error messages to stdout - redirect them to stderr
          [stdout, stderr].each do |io|
            unless (io_str = io.read).strip.empty? then $stderr.puts(io_str) end
          end
        end

        @results = ::QUnited::Results.from_javascript_produced_yaml(IO.read(results_file))
      end

      private

      attr_accessor :tests_file

      def tests_page_content
        ERB.new(IO.read(File.expand_path('../support/tests_page.html.erb', __FILE__))).result(binding)
      end

      def script_tag(file)
        js_file_path, tests_file_path = Pathname.new(file).realpath, Pathname.new(tests_file)
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
