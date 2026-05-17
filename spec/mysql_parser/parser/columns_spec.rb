RSpec.describe "aggregate functions" do
  def parse(sql)
    MysqlParser::Parser.new(sql).parse[:select]
  end

  it "parses aggregate function" do
    result = parse("SELECT COUNT(*) FROM users")

    expect(result).to eq([
      { column_name: "*", column_alias: nil, aggregate: "count" }
    ])
  end

  it "parses aggregate with alias" do
    result = parse("SELECT AVG(price) AS avg_price FROM products")

    expect(result).to eq([
      { column_name: "price", column_alias: "avg_price", aggregate: "avg" }
    ])
  end

  it "parses mix of aggregate and plain columns" do
    result = parse("SELECT id, COUNT(*) AS total, name FROM users")

    expect(result).to eq([
      { column_name: "id", column_alias: nil, aggregate: nil },
      { column_name: "*", column_alias: "total", aggregate: "count" },
      { column_name: "name", column_alias: nil, aggregate: nil }
    ])
  end

  it "parses DISTINCT as aggregate on first column" do
    result = parse("SELECT DISTINCT name, email FROM users")

    expect(result).to eq([
      { column_name: "name", column_alias: nil, aggregate: "distinct" },
      { column_name: "email", column_alias: nil, aggregate: nil }
    ])
  end

  it "parses DISTINCT with single column" do
    result = parse("SELECT DISTINCT id FROM users")

    expect(result).to eq([
      { column_name: "id", column_alias: nil, aggregate: "distinct" }
    ])
  end
end
