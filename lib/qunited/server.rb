require 'webrick'
require 'erb'
require 'pathname'

module QUnited
  class Server
    DEFAULT_PORT = 3040

    ASSETS_PATH = File.expand_path('../server', __FILE__)

    SOURCE_FILE_PREFIX = 'qunited-source-file'
    TEST_FILE_PREFIX = 'qunited-test-file'

    QUNITED_ASSET_FILE_PREFIX = 'qunited-asset'

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

      @server = ::WEBrick::HTTPServer.new(server_options)

      @server.mount_proc '/' do |request, response|
        response.status = 200

        case request.path
        when /^\/#{SOURCE_FILE_PREFIX}\/(.*)/, /^\/#{TEST_FILE_PREFIX}\/(.*)/
          response['Content-Type'] = 'application/javascript'
          response.body = IO.read($1)
        when /^\/#{QUNITED_ASSET_FILE_PREFIX}\/(.*)/
          filename = $1
          response['Content-Type'] = (filename =~ /\.js$/) ? 'application/javascript' : 'text/css'
          response.body = IO.read(asset_path filename)
        else
          response['Content-Type'] = 'text/html'
          test_suite_template = ::ERB.new(IO.read(asset_path 'test_suite.html.erb'))
          response.body = test_suite_template.result(binding)
        end
      end

      ['INT', 'TERM'].each do |signal|
        trap(signal) { @server.shutdown }
      end
    end

    def start
      $stderr.puts "Serving QUnit test suite on port #{@port}\nCtrl-C to shutdown"
      @server.start
    end

    private

    def asset_path(filename)
      File.join(ASSETS_PATH, filename)
    end

    def source_script_tag(file_path)
      script_tag "#{SOURCE_FILE_PREFIX}/#{file_path}"
    end

    def test_script_tag(file_path)
      script_tag "#{TEST_FILE_PREFIX}/#{file_path}"
    end

    def asset_script_tag(filename)
      script_tag "#{QUNITED_ASSET_FILE_PREFIX}/#{filename}"
    end

    def asset_css_tag(filename)
      %{<link rel="stylesheet" type="text/css" href="#{QUNITED_ASSET_FILE_PREFIX}/#{filename}">}
    end

    def script_tag(src)
      %{<script type="text/javascript" src="#{src}"></script>}
    end
  end
end
