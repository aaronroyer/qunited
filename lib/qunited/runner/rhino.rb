require 'tempfile'
require 'fileutils'
require 'yaml'

module QUnited
  module Runner
    class Rhino < Base
      def can_run?
        # TODO: test that you have Java
      end

      def run
        js_dir = File.expand_path('../rhino/js', __FILE__)

        js_jar, runner = File.join(js_dir, 'js.jar'), File.join(js_dir, 'qunit-runner.js')

        source_files_args = @source_files.map { |sf| %{"#{sf}"} }.join(' ')
        test_files_args = @test_files.map { |tf| %{"#{tf}"} }.join(' ')

        tmp_file = Tempfile.new('qunited_results')
        tmp_file.close

        cmd = %{java -jar "#{js_jar}" -opt -1 "#{runner}" "#{js_dir}" "#{tmp_file.path}"}
        cmd << " #{source_files_args} -- #{test_files_args}"

        `#{cmd}`

        @raw_results = clean_up_results(YAML.load(IO.read(tmp_file)))
        @results = ::QUnited::Results.new @raw_results
        self
      end

      private

      def clean_up_results(results)
        results.map! { |mod_results| symbolize_keys mod_results }
        results.each do |mod_results|
          mod_results[:tests].map! { |test| clean_up_test_results(symbolize_keys(test)) }
        end
      end

      def clean_up_test_results(test_results)
        test_results[:start] = DateTime.parse(test_results[:start])
        test_results[:duration] = Float(test_results[:duration])
        test_results[:failures].map! { |failure| symbolize_keys failure }
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
