require 'pathname'
require 'tempfile'
require 'fileutils'
require 'erb'
require 'open3'

module QUnited
  module Driver
    class PhantomJs < Base
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
        return <<-SCRIPT_ELEMENT
<script type="text/javascript">
  #{IO.read(file)}
</script>
        SCRIPT_ELEMENT
      end
    end
  end
end
