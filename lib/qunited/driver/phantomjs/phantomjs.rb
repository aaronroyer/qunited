require 'pathname'
require 'tempfile'
require 'fileutils'
require 'erb'
require 'open3'

module QUnited
  module Driver
    class PhantomJs < Base
      RUNNER_JS = File.expand_path('../support/runner.js', __FILE__)

      # Determines whether this driver available to use.
      # Checks whether phantomjs is on the PATH.
      def self.available?
        !!which('phantomjs')
      end

      def name
        'PhantomJS'
      end

      def command
        %|phantomjs "#{RUNNER_JS}" "#{@tests_file.path}"|
      end
    end
  end
end
