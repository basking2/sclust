require 'rake'

Gem::Specification.new do |spec|
    spec.name = 'sclust'
    spec.version = '1.0.0'
    spec.platform = Gem::Platform::RUBY
    spec.summary = 'k-mean clustering.'
    spec.email = 'basking2@rubyforge.org.com'
    spec.homepage = 'http://sclust.rubyforge.org'
    spec.rubyforge_project='http://sclust.rubyforge.org/'
    spec.author = 'Sam Baskinger'
    spec.description='A k-mean text clustering library for ruby.'
    spec.required_ruby_version = '>= 1.6.8'
    # spec.require_paths = [ 'lib' ] (defalt)
    spec.require_paths = [ 'lib' ]
    spec.files = FileList[ 'lib/**/*.rb' ].to_a
    spec.add_dependency('log4r', '>=1.0.5')
    #spec.add_dependency('sources', '>=0.0.1')
    spec.add_dependency('mechanize', '>=0.9.3') # Required for blog clustering script.
    spec.test_files = FileList[ 'tests/*rb', 'tests/**/*.rb' ] .to_a
    spec.has_rdoc = true
end
