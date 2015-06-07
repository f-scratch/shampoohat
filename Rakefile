require 'rake/testtask'

desc 'Default target - build.'
task :default => [:build, :test]

desc 'Package the Common library into a gem file.'
task :build do
  result = system('/usr/bin/env gem build shampoohat.gemspec')
  raise 'Build failed.' unless result
end

desc 'Perform the unit testing.'
Rake::TestTask.new do |t|
  test_files_mask = File.join(File.dirname(__FILE__), 'test', 'test_*.rb')
  t.test_files = FileList[Dir.glob(test_files_mask)]
end

desc 'Run tests coverage tool.'
task :coverage do
  result = system('/usr/bin/env ruby test/coverage.rb')
  raise 'Coverage run failed.' unless result
end
