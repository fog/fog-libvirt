SimpleCov.add_filter '/minitests/'
SimpleCov.add_filter '/tests/'
SimpleCov.enable_coverage :branch
SimpleCov.ignore_branches :implicit_else if SimpleCov.respond_to?(:ignore_branches)
