# mysql-parser

Parses MySQL SELECT queries into structured Ruby hashes. Built for query analysis — understand query shape, count joins, detect aggregates, inspect conditions.

## Installation

```ruby
gem "mysql-parser", git: "https://github.com/umairabid/ruby-mysql-parser.git"
```

## Usage

```ruby
require "mysql_parser"

result = MysqlParser.parse("SELECT id, name FROM users WHERE active = 1")
```

### Columns

```ruby
MysqlParser.parse("SELECT id, name AS username FROM users")[:select]
# [
#   { column_name: "id", column_alias: nil },
#   { column_name: "name", column_alias: "username" }
# ]
```

Subquery as column:

```ruby
MysqlParser.parse("SELECT (SELECT MAX(id) FROM users) AS max_id FROM dual")[:select][0]
# {
#   column_name: { select: [{ column_name: "id", column_alias: nil, aggregate: "max" }], from: { name: "users", alias: nil } },
#   column_alias: "max_id",
#   aggregate: nil
# }
```

### Aggregate Functions

Supported: `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `GROUP_CONCAT`, `JSON_ARRAYAGG`, `JSON_OBJECTAGG`

```ruby
MysqlParser.parse("SELECT COUNT(*) AS total, name FROM users")[:select]
# [
#   { type: :aggregate, aggregate: "count", column_alias: "total", columns: [{ column_name: "*", column_alias: nil }] },
#   { column_name: "name", column_alias: nil }
# ]
```

### DISTINCT

Supports global `DISTINCT` and `DISTINCT` within aggregates.

```ruby
MysqlParser.parse("SELECT DISTINCT name FROM users")[:select]
# [{ type: :distinct, columns: [{ column_name: "name", column_alias: nil }] }]
```

### FROM

```ruby
MysqlParser.parse("SELECT * FROM users AS u")[:from]
# { name: "users", alias: "u" }
```

Subquery in FROM:

```ruby
MysqlParser.parse("SELECT * FROM (SELECT id FROM users) AS subq")[:from]
# { name: { select: [...], from: { name: "users", alias: nil } }, alias: "subq" }
```

### JOINs

Supports `JOIN`, `INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN`, `CROSS JOIN`. Tables can be subqueries.

```ruby
MysqlParser.parse(
  "SELECT * FROM users LEFT JOIN orders AS o ON users.id = o.user_id AND o.active = 1"
)[:joins]
# [
#   {
#     join_type: "left join",
#     table: { name: "orders", alias: "o" },
#     on: [
#       { left_side: "users.id", operator: "=", right_side: "o.user_id" },
#       { joiner: "and", left_side: "o.active", operator: "=", right_side: "1" }
#     ]
#   }
# ]
```

Multiple joins:

```ruby
MysqlParser.parse(
  "SELECT * FROM users JOIN orders ON users.id = orders.user_id LEFT JOIN items ON orders.id = items.order_id"
)[:joins].length
# 2
```

Join with subquery table:

```ruby
MysqlParser.parse(
  "SELECT * FROM users JOIN (SELECT user_id FROM orders) AS o ON users.id = o.user_id"
)[:joins][0][:table]
# { name: { select: [...], from: { name: "orders", alias: nil } }, alias: "o" }
```

### WHERE

Operators: `=`, `!=`, `<>`, `<`, `>`, `<=`, `>=`, `LIKE`, `NOT LIKE`, `IN`, `NOT IN`, `IS`, `IS NOT`, `BETWEEN`

Supports string literals with spaces.

```ruby
MysqlParser.parse("SELECT * FROM users WHERE name = 'John Doe'")[:where]
# [{ left_side: "name", operator: "=", right_side: "'John Doe'" }]
```

Grouped conditions:

```ruby
MysqlParser.parse("SELECT * FROM users WHERE (name = John OR name = Jane) AND active = 1")[:where]
# [
#   [
#     { left_side: "name", operator: "=", right_side: "John" },
#     { joiner: "or", left_side: "name", operator: "=", right_side: "Jane" }
#   ],
#   { joiner: "and", left_side: "active", operator: "=", right_side: "1" }
# ]
```

IN with values and subqueries:

```ruby
MysqlParser.parse("SELECT * FROM users WHERE id IN (1, 2, 3)")[:where]
# [{ left_side: "id", operator: "in", right_side: "( 1 , 2 , 3 )" }]

MysqlParser.parse("SELECT * FROM users WHERE id IN (SELECT user_id FROM orders)")[:where][0][:right_side]
# { select: [...], from: { name: "orders", alias: nil } }
```

BETWEEN:

```ruby
MysqlParser.parse("SELECT * FROM users WHERE age BETWEEN 18 AND 35")[:where]
# [{ left_side: "age", operator: "between", right_side: "18 AND 35" }]
```

### Subqueries

Subqueries are supported anywhere and produce nested hashes with the same structure.

In columns:

```ruby
MysqlParser.parse("SELECT (SELECT MAX(id) FROM users) AS max_id FROM dual")[:select][0]
# {
#   select: [{ type: :aggregate, aggregate: "max", columns: [{ column_name: "id", column_alias: nil }], column_alias: nil }],
#   from: { name: "users", alias: nil },
#   column_alias: "max_id"
# }
```

In FROM:

```ruby
MysqlParser.parse("SELECT * FROM (SELECT id FROM users) AS subq")[:from][:name]
# { select: [{ column_name: "id", column_alias: nil }], from: { name: "users", alias: nil } }
```

In JOINs:

```ruby
MysqlParser.parse("SELECT * FROM users JOIN (SELECT user_id FROM orders) AS o ON users.id = o.user_id")[:joins][0][:table][:name]
# { select: [{ column_name: "user_id", column_alias: nil }], from: { name: "orders", alias: nil } }
```

In WHERE (via IN):

```ruby
MysqlParser.parse("SELECT * FROM users WHERE id IN (SELECT user_id FROM orders)")[:where][0][:right_side]
# { select: [...], from: { name: "orders", alias: nil } }
```

### ORDER BY

Defaults to `"asc"` when direction is omitted.

```ruby
MysqlParser.parse("SELECT * FROM users ORDER BY created_at DESC, name")[:order_by]
# [
#   { column: "created_at", direction: "desc" },
#   { column: "name", direction: "asc" }
# ]
```

### LIMIT

```ruby
MysqlParser.parse("SELECT * FROM users LIMIT 10")[:limit]
# "10"
```

### UNION / UNION ALL

Single SELECT returns a plain hash. UNION wraps multiple selects in a `union` array — first entry has no `union_type`, subsequent ones do.

```ruby
MysqlParser.parse("SELECT id FROM users UNION ALL SELECT id FROM admins")
# {
#   union: [
#     { select: [{ column_name: "id", column_alias: nil, aggregate: nil }], from: { name: "users", alias: nil } },
#     { union_type: "union all", select: [{ column_name: "id", column_alias: nil, aggregate: nil }], from: { name: "admins", alias: nil } }
#   ]
# }
```

Chains of N unions:

```ruby
MysqlParser.parse("SELECT id FROM a UNION SELECT id FROM b UNION ALL SELECT id FROM c")[:union].length
# 3
```

## Not Supported

- `GROUP BY`, `HAVING`
- Multi-token expressions in columns (`CASE WHEN ... END`, arithmetic like `price * qty`)
- `OFFSET`
- Window functions (`OVER`, `PARTITION BY`)

## Development

```
bin/setup
bundle exec rspec
```

Use `bin/console` for an interactive session.

### TiDB Parser (Go)

A Go-based wrapper around [PingCap's TiDB parser](https://github.com/pingcap/tidb/pkg/parser) is available under `tools/` as a development utility for validating our implementation against a full MySQL parser.

#### Setup

```
brew install go
cd tools/tidb-parser
go build -o tidb-parser .
```

#### CLI

```
tools/tidb-parser/tidb-parser "SELECT id, name FROM users WHERE active = 1"
echo "SELECT id FROM users" | tools/tidb-parser/tidb-parser
```

#### Ruby

```ruby
require_relative "tools/tidb_parser"

result = TidbParser.parse("SELECT id, name FROM users WHERE active = 1")
result.dig("Fields", "Fields").map { |f| f.dig("Expr", "Name", "Name", "O") }
# => ["id", "name"]
```
