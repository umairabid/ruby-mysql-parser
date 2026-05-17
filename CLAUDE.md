# fs-mysql-parser

Ruby gem for parsing MySQL SELECT queries into structured hashes.

## Architecture

### Lexer (`lib/mysql_parser/lexer.rb`)
- Normalizes SQL by inserting spaces around `(`, `)`, `,` then splits on whitespace
- Cursor interface: `current` (read), `advance` (read + move), `peek` (lookahead)
- `keyword?` checks if current token (downcased) is in TOKENS array
- All child parsers share the same lexer instance — advancing in one advances for all

### Tokens (`lib/mysql_parser/tokens.rb`)
- Keyword constants: SELECT, FROM, AS, LIMIT, WHERE, AND, OR
- `TOKENS` array — used by `keyword?` to detect keyword boundaries (stops column/from parsing)
- `OPERATORS` array — reference list of all comparison operators, includes multi-word: `is not`, `not in`, `not like`

### Parser (`lib/mysql_parser/parser.rb`)
- Main loop: `while @lexer.current` with `case current_keyword`
- Each keyword is a `when` branch that advances past the keyword then delegates to a child parser
- `current_keyword` returns downcased token only if it's a keyword, nil otherwise
- Unknown tokens are skipped via `else` branch
- Returns hash with keys: `:select`, `:from`, `:where`, `:limit`

### Child Parsers (under `lib/mysql_parser/parser/`)
All receive the lexer in constructor, include Helpers concern.

**Helpers** (`parser/helpers.rb`) — shared concern with:
- `subquery?` — checks `(` followed by `select` (via peek)
- `parse_subquery` — collects tokens between matched parens (depth tracking), recursively parses via new Parser instance

**Columns** (`parser/columns.rb`) — parses column list:
- Loops until keyword or EOF
- Each column: `{ column_name:, column_alias: }` where column_name can be string or subquery result
- Handles AS aliases, comma separation

**From** (`parser/from.rb`) — parses FROM clause:
- Returns `{ name:, alias: }` where name can be string or subquery result
- Handles AS aliases

**Where** (`parser/where.rb`) — parses WHERE conditions:
- `result[:where]` is always an array of conditions
- First condition has no joiner, subsequent ones have `joiner:` key ("and"/"or")
- Simple condition: `{ left_side:, operator:, right_side: }`
- Parenthesized groups are nested arrays (no wrapper key) — even single condition in parens becomes array
- `parse_operator` uses OPERATORS with two-word lookahead (current + peek) before falling back to single token
- `parse_right_side` dispatches by context: subquery → `parse_subquery`, `(` → `parse_value_list` (returns array), BETWEEN → consumes `value AND value` (returns two-element array, AND is not treated as joiner), otherwise → single token

## Output Structure

```ruby
MysqlParser.parse("SELECT id, name FROM users WHERE active = 1 AND role = admin")
# {
#   select: [
#     { column_name: "id", column_alias: nil },
#     { column_name: "name", column_alias: nil }
#   ],
#   from: { name: "users", alias: nil },
#   where: [
#     { left_side: "active", operator: "=", right_side: "1" },
#     { joiner: "and", left_side: "role", operator: "=", right_side: "admin" }
#   ]
# }
```

Subqueries anywhere (columns, from, where) produce nested hashes with the same structure.

## Design Decisions

- Lexer splits on whitespace only — tokens are space-separated after normalization
- TOKENS array is the single source of truth for keyword detection and boundary stopping
- OPERATORS array is the single source of truth for operator matching (including multi-word)
- Child parsers own their parsing logic but share the lexer cursor — advancing in a child parser moves the position for everyone
- Subqueries detected by `(` + `select` pattern, parsed recursively via new Parser instance
- WHERE conditions are flat arrays, not binary trees — joiners live on individual conditions
- Parenthesized groups in WHERE are just nested arrays from recursive `parse_conditions`

## Running Specs

```
bundle exec rspec
```

## Not Yet Implemented

- JOIN clauses
- ORDER BY, GROUP BY, HAVING
- String literal handling (quoted values)
