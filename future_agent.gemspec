Gem::Specification.new do |s|
  s.name = 'future_agent'
  s.version = '0.1'

  s.required_ruby_version = ">= 1.8.7"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sven Riedel"]
  s.date = %q{2010-07-17}
  s.description = %q{Compute values asynchronously as seen with Clojure agents, but uses multi-processing instead of multi-threading.}
  s.summary = %q{Computes values asynchronously.}
  s.email = %q{sr@gimp.org}

  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}

  s.extra_rdoc_files = %W{ README.rdoc }
  s.files = %W{ README.rdoc
                VERSION
                lib/future_agent/future_agent.rb
                spec/spec_helper.rb
                spec/future_agent/future_agent_spec.rb
                common_test_cases
              }
end

