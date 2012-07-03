require 'erb'
require 'tempfile'
require 'fileutils'
require 'yaml'
require 'open3'

module QUnited
  module Driver
    class PhantomJs < Base
      def run
        tmp_file = Tempfile.new(['tests_page', '.html'])
        @qunit_file = File.expand_path('../js/qunit.js', __FILE__)
        @yaml_js_file = File.expand_path('../js/yaml.js', __FILE__)
        tmp_file.write(tests_page_content)
        tmp_file.close
        cmd = %{phantomjs "#{File.expand_path('../js/run-qunit.js', __FILE__)}" #{tmp_file.path}}
        results_yaml = `#{cmd}`

        @raw_results = clean_up_results(YAML.load(results_yaml))
        @results = ::QUnited::Results.new @raw_results
        self
      end

      private

      def tests_page_content
        ERB.new(IO.read(File.expand_path('../tests_page.html.erb', __FILE__))).result(binding)
      end

      def script_tag(file)
        return <<-SCRIPT_ELEMENT
<script type="text/javascript">
  #{IO.read(file)}
</script>
        SCRIPT_ELEMENT
      end

      def clean_up_results(results)
        results.map! { |mod_results| symbolize_keys mod_results }
        results.each do |mod_results|
          mod_results[:tests].map! { |test| clean_up_test_results(symbolize_keys(test)) }
        end
      end

      def clean_up_test_results(test_results)
        test_results[:start] = DateTime.parse(test_results[:start])
        test_results[:duration] = Float(test_results[:duration])
        test_results[:assertion_data].map! { |data| symbolize_keys data }
        test_results
      end

      def symbolize_keys(hash)
        new_hash = {}
        hash.keys.each { |key| new_hash[key.to_sym] = hash[key] }
        new_hash
      end
    end
  end
end
