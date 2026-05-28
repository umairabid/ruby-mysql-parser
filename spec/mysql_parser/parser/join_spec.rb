RSpec.describe MysqlParser::Parser::Join do
  def parse(sql)
    MysqlParser::Parser.new(sql).parse[:joins]
  end

  it "parses simple JOIN" do
    result = parse("SELECT * FROM users JOIN orders ON users.id = orders.user_id")

    expect(result.length).to eq(1)
    expect(result[0][:join_type]).to eq("join")
    expect(result[0][:table]).to eq({ name: "orders", alias: nil })
    expect(result[0][:on]).to eq([
      { left_side: "users.id", operator: "=", right_side: "orders.user_id" }
    ])
  end

  it "parses INNER JOIN" do
    result = parse("SELECT * FROM users INNER JOIN orders ON users.id = orders.user_id")

    expect(result[0][:join_type]).to eq("inner join")
    expect(result[0][:table]).to eq({ name: "orders", alias: nil })
  end

  it "parses LEFT JOIN" do
    result = parse("SELECT * FROM users LEFT JOIN orders ON users.id = orders.user_id")

    expect(result[0][:join_type]).to eq("left join")
  end

  it "parses RIGHT JOIN" do
    result = parse("SELECT * FROM users RIGHT JOIN orders ON users.id = orders.user_id")

    expect(result[0][:join_type]).to eq("right join")
  end

  it "parses CROSS JOIN" do
    result = parse("SELECT * FROM users CROSS JOIN orders ON users.id = orders.user_id")

    expect(result[0][:join_type]).to eq("cross join")
  end

  it "parses JOIN with table alias" do
    result = parse("SELECT * FROM users JOIN orders AS o ON users.id = o.user_id")

    expect(result[0][:table]).to eq({ name: "orders", alias: "o" })
  end

  it "parses JOIN with multiple ON conditions" do
    result = parse("SELECT * FROM users JOIN orders ON users.id = orders.user_id AND orders.active = 1")

    expect(result[0][:on]).to eq([
      { left_side: "users.id", operator: "=", right_side: "orders.user_id" },
      { joiner: "and", left_side: "orders.active", operator: "=", right_side: "1" }
    ])
  end

  it "parses multiple JOINs" do
    sql = "SELECT * FROM users JOIN orders ON users.id = orders.user_id LEFT JOIN items ON orders.id = items.order_id"
    result = parse(sql)

    expect(result.length).to eq(2)
    expect(result[0][:join_type]).to eq("join")
    expect(result[0][:table]).to eq({ name: "orders", alias: nil })
    expect(result[1][:join_type]).to eq("left join")
    expect(result[1][:table]).to eq({ name: "items", alias: nil })
  end

  it "parses JOIN with subquery table" do
    sql = "SELECT * FROM users JOIN (SELECT id, user_id FROM orders) AS o ON users.id = o.user_id"
    result = parse(sql)

    expect(result[0][:join_type]).to eq("join")
    expect(result[0][:table][:name][:select]).to eq([
      { column_name: "id", column_alias: nil },
      { column_name: "user_id", column_alias: nil }
    ])
    expect(result[0][:table][:name][:from]).to eq({ name: "orders", alias: nil })
    expect(result[0][:table][:alias]).to eq("o")
  end

  it "parses JOIN followed by WHERE" do
    sql = "SELECT * FROM users JOIN orders ON users.id = orders.user_id WHERE users.active = 1"
    result = MysqlParser::Parser.new(sql).parse

    expect(result[:joins].length).to eq(1)
    expect(result[:joins][0][:table]).to eq({ name: "orders", alias: nil })
    expect(result[:where]).to eq([
      { left_side: "users.active", operator: "=", right_side: "1" }
    ])
  end
end
