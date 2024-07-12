source "https://rubygems.org"

group :development, :test do
  # This is here because gemspec doesn't support require: false
  gem "netrc", :require => false
  gem "octokit", :require => false
end

# 0.8.3 breaks our tests
gem "ruby-libvirt", ">= 0.7.0", "< 0.8.3"

gemspec
