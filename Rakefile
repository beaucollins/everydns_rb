require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test all'
Rake::TestTask.new('test:api') do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/api/*_test.rb'
  t.verbose = true
end

desc 'Test unit tests'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/unit/*_test.rb'
  t.verbose = true
end
