RSpec.describe "Columns Parser" do
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

  context "when using distinct" do
    it "parses distinct on one column" do
      sql = "SELECT DISTINCT name FROM users"
      result = parse(sql)

      puts result.inspect
    end

    it "parses distinct on multiple columns" do
    end

    it "parses distinct with aggregate function" do
    end

    it "parses aggregate with multiple distinct columns" do
    end

    it "parses nested aggregates" do
    end
  end
end
