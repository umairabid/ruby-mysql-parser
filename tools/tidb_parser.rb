require "json"
require "open3"

class TidbParser
  BINARY = File.expand_path("tidb-parser/tidb-parser", __dir__)

  def self.parse(sql)
    new.parse(sql)
  end

  def parse(sql)
    stdout, stderr, status = Open3.capture3(BINARY, sql)

    unless status.success?
      raise "tidb-parser failed: #{stderr.strip}"
    end

    JSON.parse(stdout).first
  end
end
