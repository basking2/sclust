require 'rubygems'
require 'rubygems/package_task'
require 'ruby-prof/task'
require 'fileutils'
require 'rdoc'
require 'rspec/core/rake_task'

rspec = RSpec::Core::RakeTask.new(:spec)
rspec.rspec_opts = [ ]
rspec.rspec_opts << '-t ~performance' unless ENV.key? 'PERF'
rspec.rspec_opts << '-t ~slow'        unless ENV.key? 'SLOW'

RDoc::Task.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
end

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = 'k-mean/lda clustering.'
  s.name = 'sclust'
  s.email = 'basking2@rubyforge.org'
  s.homepage = 'http://sclust.rubyforge.org'
  s.license = 'MIT'
  s.rubyforge_project = 'http://sclust.rubyforge.org'
  s.author = 'Sam Baskinger'
  s.version = '2.1.1'
  s.require_path = 'lib' 

  # Add binary executables
  Rake::FileList.new('bin/*').each do |fl|
    s.executables << File.basename( fl )
  end

  s.files = Rake::FileList.new('lib/**/*rb').to_a
  s.files << 'LICENSE.txt'

  s.description = <<-EOF
A k-mean and LDA text clustering library for ruby.
  EOF

  s.add_dependency('mechanize', '>=1.0.0') # For blog clustering script.
  s.add_dependency('stemmer', '>=1.0.1') # Word stemming
  s.add_dependency('nokogiri', '>=1.4.1') # HTML parsing.

  s.add_development_dependency('ruby-prof', '>=0.15.0')
end

Gem::PackageTask.new(spec) do |pkg|
  # Package customizations 
end

task :default => [ :spec, :package ]
