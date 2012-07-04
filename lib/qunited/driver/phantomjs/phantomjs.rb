require 'erb'
require 'tempfile'
require 'fileutils'
require 'yaml'
require 'open3'

module QUnited
  module Driver
    class PhantomJs < Base
      def run
        tests_file = Tempfile.new(['tests_page', '.html'])
        tests_file.write(tests_page_content)
        tests_file.close

        results_file = Tempfile.new('qunited_results')
        results_file.close

        cmd = %{phantomjs "#{File.expand_path('../support/runner.js', __FILE__)}" }
        cmd << %{#{tests_file.path} #{results_file.path}}

        Open3.popen3(cmd) do |stdin, stdout, stderr|
          unless (out = stdout.read).strip.empty? then $stderr.puts(out) end
          unless (err = stderr.read).strip.empty? then $stderr.puts(err) end
        end

        @raw_results = clean_up_results(YAML.load(IO.read(results_file)))
        @results = ::QUnited::Results.new @raw_results
      end

      private

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
