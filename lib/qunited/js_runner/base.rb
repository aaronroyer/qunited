module QUnited
  module JsRunner
    class Base
      attr_reader :results

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

      def can_run?
        false
      end

      def run
        raise 'run not implemented'
      end
    end
  end
end
