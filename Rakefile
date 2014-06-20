desc 'Run server'
task :server do
  sh 'RACK_ENV=production puma -C puma.rb'
end

desc 'Run server'
task s: :server

desc 'Run the benchmark'
task :benchmark do
  sh 'wrk -t 30 -c 300 -d 2s http://127.0.0.1:9292/'
end

desc 'Run the benchmark'
task b: :benchmark

namespace :db do
  desc 'Create database'
  task :create do
    sh "createdb sequel_test"
  end

  desc 'Drop database'
  task :drop do
    sh "dropdb sequel_test"
  end
end
