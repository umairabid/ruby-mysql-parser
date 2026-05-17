RSpec.describe MysqlParser::Parser::Where do
  def parse(sql)
    MysqlParser::Parser.new(sql).parse[:where]
  end

  it "parses simple condition" do
    result = parse("SELECT * FROM users WHERE id = 1")

    expect(result).to eq([
      { left_side: "id", operator: "=", right_side: "1" }
    ])
  end

  it "parses AND conditions" do
    result = parse("SELECT * FROM users WHERE id = 1 AND name = John")

    expect(result).to eq([
      { left_side: "id", operator: "=", right_side: "1" },
      { joiner: "and", left_side: "name", operator: "=", right_side: "John" }
    ])
  end

  it "parses OR conditions" do
    result = parse("SELECT * FROM users WHERE id = 1 OR id = 2")

    expect(result).to eq([
      { left_side: "id", operator: "=", right_side: "1" },
      { joiner: "or", left_side: "id", operator: "=", right_side: "2" }
    ])
  end

  it "parses three chained conditions" do
    result = parse("SELECT * FROM users WHERE a = 1 AND b = 2 AND c = 3")

    expect(result).to eq([
      { left_side: "a", operator: "=", right_side: "1" },
      { joiner: "and", left_side: "b", operator: "=", right_side: "2" },
      { joiner: "and", left_side: "c", operator: "=", right_side: "3" }
    ])
  end

  it "parses grouped conditions" do
    result = parse("SELECT * FROM users WHERE (name = John OR name = Jane) AND active = 1")

    expect(result[0]).to eq([
      { left_side: "name", operator: "=", right_side: "John" },
      { joiner: "or", left_side: "name", operator: "=", right_side: "Jane" }
    ])
    expect(result[1]).to eq({ joiner: "and", left_side: "active", operator: "=", right_side: "1" })
  end

  it "parses single condition in group" do
    result = parse("SELECT * FROM users WHERE (id = 1)")

    expect(result).to eq([
      [{ left_side: "id", operator: "=", right_side: "1" }]
    ])
  end

  it "parses IS NOT operator" do
    result = parse("SELECT * FROM users WHERE email IS NOT null")

    expect(result).to eq([
      { left_side: "email", operator: "is not", right_side: "null" }
    ])
  end

  it "parses NOT IN operator" do
    result = parse("SELECT * FROM users WHERE id NOT IN 1")

    expect(result).to eq([
      { left_side: "id", operator: "not in", right_side: "1" }
    ])
  end

  it "parses NOT LIKE operator" do
    result = parse("SELECT * FROM users WHERE name NOT LIKE test")

    expect(result).to eq([
      { left_side: "name", operator: "not like", right_side: "test" }
    ])
  end

  it "parses BETWEEN with AND" do
    result = parse("SELECT * FROM users WHERE age BETWEEN 18 AND 35")

    expect(result).to eq([
      { left_side: "age", operator: "between", right_side: "18 AND 35" }
    ])
  end

  it "parses BETWEEN with AND followed by another condition" do
    result = parse("SELECT * FROM users WHERE age BETWEEN 18 AND 35 AND active = 1")

    expect(result).to eq([
      { left_side: "age", operator: "between", right_side: "18 AND 35" },
      { joiner: "and", left_side: "active", operator: "=", right_side: "1" }
    ])
  end

  it "parses IN with value list" do
    result = parse("SELECT * FROM users WHERE id IN (1, 2, 3)")

    expect(result).to eq([
      { left_side: "id", operator: "in", right_side: "( 1 , 2 , 3 )" }
    ])
  end

  it "parses IN with subquery" do
    result = parse("SELECT * FROM users WHERE id IN (SELECT user_id FROM orders)")

    expect(result[0][:left_side]).to eq("id")
    expect(result[0][:operator]).to eq("in")
    expect(result[0][:right_side][:select]).to eq([{ column_name: "user_id", column_alias: nil, aggregate: nil }])
    expect(result[0][:right_side][:from]).to eq({ name: "orders", alias: nil })
  end

  it "parses EXISTS with subquery" do
    result = parse("SELECT * FROM users WHERE EXISTS (SELECT 1 FROM orders WHERE orders.user_id = users.id)")

    expect(result[0][:left_side]).to eq("exists")
    expect(result[0][:right_side]).to be_nil
    expect(result[0][:subquery][:select]).to eq([{ column_name: "1", column_alias: nil, aggregate: nil }])
    expect(result[0][:subquery][:from]).to eq({ name: "orders", alias: nil })
    expect(result[0][:subquery][:where]).to eq([
      { left_side: "orders.user_id", operator: "=", right_side: "users.id" }
    ])
  end

  it "parses EXISTS with AND condition" do
    result = parse("SELECT * FROM users WHERE EXISTS (SELECT 1 FROM orders WHERE orders.user_id = users.id) AND active = 1")

    expect(result[0][:left_side]).to eq("exists")
    expect(result[0][:subquery][:from]).to eq({ name: "orders", alias: nil })
    expect(result[1]).to eq({ joiner: "and", left_side: "active", operator: "=", right_side: "1" })
  end

  it "parses NOT EXISTS with subquery" do
    result = parse("SELECT * FROM users WHERE NOT EXISTS (SELECT 1 FROM orders WHERE orders.user_id = users.id)")

    expect(result[0][:left_side]).to eq("not exists")
    expect(result[0][:right_side]).to be_nil
    expect(result[0][:subquery][:select]).to eq([{ column_name: "1", column_alias: nil, aggregate: nil }])
    expect(result[0][:subquery][:from]).to eq({ name: "orders", alias: nil })
  end

  it "parses comparison operators" do
    expect(parse("SELECT * FROM users WHERE age > 18")[0][:operator]).to eq(">")
    expect(parse("SELECT * FROM users WHERE age >= 18")[0][:operator]).to eq(">=")
    expect(parse("SELECT * FROM users WHERE age < 18")[0][:operator]).to eq("<")
    expect(parse("SELECT * FROM users WHERE age <= 18")[0][:operator]).to eq("<=")
    expect(parse("SELECT * FROM users WHERE age != 18")[0][:operator]).to eq("!=")
    expect(parse("SELECT * FROM users WHERE age <> 18")[0][:operator]).to eq("<>")
    expect(parse("SELECT * FROM users WHERE name LIKE test")[0][:operator]).to eq("like")
  end
end
