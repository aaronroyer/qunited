module QUnited
  module Driver
    class Base
      attr_reader :results, :source_files, :test_files

      def self.support_dir
        @@support_dir = File.expand_path('../support', __FILE__)
      end

      # Array of file names? Glob pattern?
      def initialize(source_files, test_files)
        @source_files = if source_files.is_a? String
          Dir.glob(source_files)
        elsif source_files.is_a? Array
          source_files
        end

        @test_files = if test_files.is_a? String
          Dir.glob(test_files)
        elsif test_files.is_a? Array
          test_files
        end
      end

      def run
        raise 'run not implemented'
      end

      def support_file_path(filename)
        File.join(self.class.support_dir, filename)
      end

      def support_file_contents(filename)
        IO.read(support_file_path(filename))
      end

      def name
        self.class.name.split('::')[-1]
      end

      protected

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
