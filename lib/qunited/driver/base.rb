require 'tempfile'

module QUnited
  module Driver
    class Base
      # Path of the common (to all drivers) supporting files directory
      SUPPORT_DIR = File.expand_path('../support', __FILE__)

      TEST_RESULT_START_TOKEN = 'QUNITED_TEST_RESULT_START_TOKEN'
      TEST_RESULT_END_TOKEN   = 'QUNITED_TEST_RESULT_END_TOKEN'
      TEST_RESULT_REGEX       = /#{TEST_RESULT_START_TOKEN}(.*?)#{TEST_RESULT_END_TOKEN}/m

      COFFEESCRIPT_EXTENSIONS = ['coffee', 'cs']

      attr_reader :results, :source_files, :test_files
      attr_accessor :formatter

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

      # Initialize the driver with source and test files. The files can be described either with
      # glob patterns or arrays of file names.
      def initialize(source_files, test_files)
        @source_files = normalize_files source_files
        @test_files = normalize_files test_files
      end

      def run
        raise 'run not implemented'
      end

      def support_file_path(filename)
        File.join(SUPPORT_DIR, filename)
      end

      def support_file_contents(filename)
        IO.read(support_file_path(filename))
      end

      def name
        self.class.name.split('::')[-1]
      end

      protected

      def send_to_formatter(method, *args)
        formatter.send(method, *args) if formatter
      end

      # Hash that maps CoffeeScript file paths to temporary compiled JavaScript files. This is
      # used partially because we need to keep around references to the temporary files or else
      # they could be deleted.
      def compiled_coffeescript_files
        @compiled_coffeescript_files ||= {}
      end

      private

      # Produces an array of JavaScript filenames from either a glob pattern or an array of
      # JavaScript or CoffeeScript filenames. Files with CoffeeScript extensions will be
      # compiled and replaced in the produced array with temp files of compiled JavaScript.
      def normalize_files(files)
        files = Dir.glob(files) if files.is_a? String

        files.map do |file|
          if COFFEESCRIPT_EXTENSIONS.include? File.extname(file).sub(/^\./, '')
            compile_coffeescript file
          else
            file
          end
        end
      end

      # Compile the CoffeeScript file with the given filename to JavaScript. Returns the full
      # path of the compiled JavaScript file. The file is created in a temporary directory.
      def compile_coffeescript(file)
        begin
          require 'coffee-script'
        rescue LoadError
          msg = <<-ERROR_MSG
You must install an additional gem to use CoffeeScript source or test files.
Run the following command (with sudo if necessary): gem install coffee-script
          ERROR_MSG
          raise UsageError, msg
        end

        compiled_js_file = Tempfile.new(["compiled_#{File.basename(file).gsub('.', '_')}", '.js'])
        compiled_js_file.write CoffeeScript.compile(File.read(file))
        compiled_js_file.close

        compiled_coffeescript_files[file] = compiled_js_file

        compiled_js_file.path
      end
    end
  end
end
