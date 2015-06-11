# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fog/libvirt/version"

Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.name              = "fog-libvirt"
  s.version           = Fog::Libvirt::VERSION

  s.summary     = "Module for the 'fog' gem to support libvirt"
  s.description = "This library can be used as a module for 'fog' or as standalone libvirt provider."

  s.authors  = ["geemus (Wesley Beary)"]
  s.email    = "geemus@gmail.com"
  s.homepage = "http://github.com/fog/fog-libvirt"
  s.license  = "MIT"

  s.require_paths = %w[lib]

  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = %w[README.md]

  s.add_dependency("fog-core", "~> 1.27", ">= 1.27.4")
  s.add_dependency("fog-json")
  s.add_dependency("fog-xml", "~> 0.1.1")
  s.add_dependency('ruby-libvirt','~> 0.5.0')
  s.add_dependency('mime-types','< 2.0') if RUBY_VERSION < '1.9'
  s.add_dependency('nokogiri', '< 1.6') if RUBY_VERSION < '1.9'
  s.add_dependency('octokit', '< 3.0') if RUBY_VERSION < '1.9'
  s.add_dependency('rest-client', '<= 1.7.0') if RUBY_VERSION < '1.9'

  # Fedora and derivates need explicit require
  s.add_dependency("json")

  s.add_development_dependency("minitest")
  s.add_development_dependency("minitest-stub-const")
  s.add_development_dependency("pry")
  s.add_development_dependency("rake")
  s.add_development_dependency("rubocop") if RUBY_VERSION > "1.9"
  s.add_development_dependency("shindo", "~> 0.3.4")
  s.add_development_dependency("simplecov")
  s.add_development_dependency("yard")

  # Let's not ship dot files and gemfiles
  git_files = `git ls-files`.split("\n")
  s.files = git_files.delete_if{ |f| f =~ /^\..*/ || f =~ /^gemfiles\/*/ }
  s.test_files = `git ls-files -- {spec,tests}/*`.split("\n")
end
