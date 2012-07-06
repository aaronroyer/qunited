module QUnited
  module Driver
    class Base
      attr_reader :results, :source_files, :test_files

      # Finds an executable on the PATH. Returns the absolute path of the
      # executable if found, otherwise nil.
      def self.which(cmd)
        exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
        ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
          exts.each do |ext|
            exe = "#{path}/#{cmd}#{ext}"
            return exe if File.executable? exe
          end
        end
        return nil
      end

      # Get the path of the common (to all drivers) supporting files directory
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
    end
  end
end
