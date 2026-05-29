module MysqlParser
  SELECT = "select"
  FROM = "from"
  AS = "as"
  LIMIT = "limit"
  WHERE = "where"
  AND = "and"
  OR = "or"
  JOIN = "join"
  INNER = "inner"
  LEFT = "left"
  RIGHT = "right"
  CROSS = "cross"
  ON = "on"
  ORDER = "order"
  BY = "by"
  ASC = "asc"
  DESC = "desc"
  DISTINCT = "distinct"

  GROUP = "group"
  HAVING = "having"

  UNION = "union"
  ALL = "all"

  EXISTS = "exists"
  NOT_EXISTS = "not exists"

  TOKENS = [SELECT, FROM, AS, LIMIT, WHERE, AND, OR, JOIN, INNER, LEFT, RIGHT, CROSS, ON, ORDER, GROUP, HAVING, ASC, DESC, UNION].freeze

  OPERATORS = ["=", "!=", "<>", "<", ">", "<=", ">=", "like", "not like", "in", "not in", "is", "is not", "between"].freeze

  AGGREGATE_FUNCTIONS = %w[count sum avg min max group_concat json_arrayagg json_objectagg].freeze
end
