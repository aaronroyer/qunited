require 'rubygems'
require 'minitest/autorun'
require 'mocha/setup'

require File.join(File.dirname(__FILE__), *%w[.. lib qunited])

FIXTURES_DIR = File.expand_path('../fixtures', __FILE__)
