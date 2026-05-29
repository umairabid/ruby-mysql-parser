require_relative "mysql_parser/version"
require_relative "mysql_parser/tokens"
require_relative "mysql_parser/lexer"
require_relative "mysql_parser/parser/helpers"
require_relative "mysql_parser/parser/columns"
require_relative "mysql_parser/parser/from"
require_relative "mysql_parser/parser/where"
require_relative "mysql_parser/parser/join"
require_relative "mysql_parser/parser/order_by"
require_relative "mysql_parser/parser/group_by"
require_relative "mysql_parser/parser/having"
require_relative "mysql_parser/parser"

module MysqlParser
  def self.parse(sql)
    Parser.new(sql).parse
  end
end
