require_relative "lib/mysql_parser/version"

Gem::Specification.new do |spec|
  spec.name = "mysql-parser"
  spec.version = MysqlParser::VERSION
  spec.authors = ["Umair Abid"]
  spec.summary = "MySQL query parser for Ruby"
  spec.homepage = "https://github.com/umairabid/ruby-mysql-parser"
  spec.required_ruby_version = ">= 3.0"

  spec.files = Dir["lib/**/*", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
  spec.add_development_dependency "rubocop-rake", "~> 0.6"
  spec.add_development_dependency "rubocop-rspec", "~> 3.0"
end
