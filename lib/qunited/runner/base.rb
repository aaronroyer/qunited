module QUnited
  module Runner
    class Base
      attr_reader :results

      # Array of file names? Glob pattern?
      def initialize(source_files, test_files)
        @source_files, @test_files = Dir.glob(source_files), Dir.glob(test_files)
      end

      def can_run?
        false
      end

      def run
      end
    end
  end
end
