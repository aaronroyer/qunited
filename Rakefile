require "bundler/gem_tasks"
require 'rake/testtask'

task :default => [:test]

Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.pattern = 'test/unit/**/test_*.rb'
end
