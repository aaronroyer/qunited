require 'webrick'
require 'erb'
require 'pathname'
require 'tempfile'

module QUnited
  class Server
    DEFAULT_PORT = 3040

    ASSETS_PATH = File.expand_path('../server', __FILE__)

    SOURCE_FILE_PREFIX = 'qunited-source-file'
    TEST_FILE_PREFIX = 'qunited-test-file'

    QUNITED_ASSET_FILE_PREFIX = 'qunited-asset'

    COFFEESCRIPT_EXTENSIONS = ['coffee', 'cs']

    attr_accessor :source_files, :test_files

    def initialize(opts={})
      @source_files, @test_files = opts[:source_files], opts[:test_files]
      @port = opts[:port] || DEFAULT_PORT

      server_options = {
        :Port => @port
      }

      unless opts[:verbose]
        server_options[:AccessLog] = []

        dev_null = '/dev/null'
        if File.exist?(dev_null) && File.writable?(dev_null)
          server_options[:Logger] = WEBrick::Log.new(dev_null)
        end
      end

      @server = create_server(server_options)
    end

    def start
      ['INT', 'TERM'].each do |signal|
        trap(signal) { @server.shutdown }
      end

      $stderr.puts "Serving QUnit test suite on port #{@port}\nCtrl-C to shutdown"
      @server.start
    end

    private

    def create_server(options)
      server = ::WEBrick::HTTPServer.new(options)

      server.mount_proc '/' do |request, response|
        response.status = 200

        case request.path
        when /^\/#{SOURCE_FILE_PREFIX}\/(.*)/, /^\/#{TEST_FILE_PREFIX}\/(.*)/
          response['Content-Type'] = 'application/javascript'
          response.body = js_file_contents($1)
        when /^\/#{QUNITED_ASSET_FILE_PREFIX}\/(.*)/
          filename = $1
          response['Content-Type'] = (filename =~ /\.js$/) ? 'application/javascript' : 'text/css'
          response.body = IO.read(qunited_asset_path filename)
        else
          response['Content-Type'] = 'text/html'
          test_suite_template = ::ERB.new(IO.read(qunited_asset_path 'test_suite.html.erb'))
          response.body = test_suite_template.result(binding)
        end
      end

      server
    end

    def source_script_tag(file_path)
      script_tag "#{SOURCE_FILE_PREFIX}/#{file_path}"
    end

    def test_script_tag(file_path)
      script_tag "#{TEST_FILE_PREFIX}/#{file_path}"
    end

    def qunited_asset_script_tag(filename)
      script_tag "#{QUNITED_ASSET_FILE_PREFIX}/#{filename}"
    end

    def qunited_asset_css_tag(filename)
      %{<link rel="stylesheet" type="text/css" href="#{QUNITED_ASSET_FILE_PREFIX}/#{filename}">}
    end

    def qunited_asset_path(filename)
      File.join(ASSETS_PATH, filename)
    end

    def script_tag(src)
      %{<script type="text/javascript" src="#{src}"></script>}
    end

    def js_file_contents(file)
      if COFFEESCRIPT_EXTENSIONS.include? File.extname(file).sub(/^\./, '')
        compile_coffeescript(file)
      else
        IO.read(file)
      end
    end

    # Compile the CoffeeScript file with the given filename to JavaScript. Returns the compiled
    # code as a string. Returns failing test JavaScript if CoffeeScript support is not installed.
    # Also adds a failing test on compilation failure.
    def compile_coffeescript(file)
      begin
        require 'coffee-script'
      rescue LoadError
        $stderr.puts <<-ERROR_MSG
You must install an additional gem to use CoffeeScript source or test files.
Run the following command (with sudo if necessary): gem install coffee-script
        ERROR_MSG

        return <<-ERROR_MSG_SCRIPT
module('CoffeeScript');
test('coffee-script gem must be installed to compile this file: #{file}', function() {
  ok(false, 'Install CoffeeScript support with `gem install coffee-script`')
});
        ERROR_MSG_SCRIPT
      end

      previously_compiled_file = compiled_coffeescript_files[file]
      if previously_compiled_file && File.mtime(file) < File.mtime(previously_compiled_file.path)
        return File.read previously_compiled_file.path
      end

      compiled_js_file = Tempfile.new(["compiled_#{File.basename(file).gsub('.', '_')}", '.js'])

      begin
        contents = CoffeeScript.compile(File.read(file))
      rescue => e
        return <<-COMPILATION_ERROR_SCRIPT
module('CoffeeScript');
test('CoffeeScript compilation error', function() {
  ok(false, "#{e.message.gsub('"', '\"')}")
});
        COMPILATION_ERROR_SCRIPT
      end

      compiled_js_file.write contents
      compiled_js_file.close

      compiled_coffeescript_files[file] = compiled_js_file

      contents
    end

    # Hash that maps CoffeeScript file paths to temporary compiled JavaScript files. This is
    # used partially because we need to keep around references to the temporary files or else
    # they could be deleted.
    def compiled_coffeescript_files
      @compiled_coffeescript_files ||= {}
    end
  end
end
