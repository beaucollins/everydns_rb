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

desc 'Generate documentation for everydns library.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'EveryDNS_rb'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
