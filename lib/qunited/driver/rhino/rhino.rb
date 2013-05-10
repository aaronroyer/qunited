require 'tempfile'
require 'fileutils'
require 'open3'

module QUnited
  module Driver
    class Rhino < Base
      JS_JAR = File.expand_path('../support/js.jar', __FILE__)
      ENV_JS = File.expand_path('../support/env.rhino.js', __FILE__)
      RUNNER_JS = File.expand_path('../support/runner.js', __FILE__)

      # Determines whether this driver available to use. Checks whether java
      # is on the PATH and whether Java is version 1.1 or greater.
      def self.available?
        java_exe = which('java')
        if java_exe
          stdin, stdout, stderr = Open3.popen3('java -version')
          begin
            version = Float(stderr.read.split("\n").first[/(\d+\.\d+)/, 1])
            version >= 1.1
          rescue
            false
          end
        end
      end

      def command
        %|java -jar "#{JS_JAR}" -opt -1 #{RUNNER_JS} #{ENV_JS} #{@tests_file.path}|
      end
    end
  end
end
