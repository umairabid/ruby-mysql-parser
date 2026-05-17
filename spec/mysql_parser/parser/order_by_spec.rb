RSpec.describe MysqlParser::Parser::OrderBy do
  def parse(sql)
    MysqlParser::Parser.new(sql).parse[:order_by]
  end

  it "parses single column" do
    result = parse("SELECT * FROM users ORDER BY name")

    expect(result).to eq([
      { column: "name", direction: "asc" }
    ])
  end

  it "parses explicit ASC" do
    result = parse("SELECT * FROM users ORDER BY name ASC")

    expect(result).to eq([
      { column: "name", direction: "asc" }
    ])
  end

  it "parses DESC" do
    result = parse("SELECT * FROM users ORDER BY created_at DESC")

    expect(result).to eq([
      { column: "created_at", direction: "desc" }
    ])
  end

  it "parses multiple columns" do
    result = parse("SELECT * FROM users ORDER BY last_name ASC, first_name ASC")

    expect(result).to eq([
      { column: "last_name", direction: "asc" },
      { column: "first_name", direction: "asc" }
    ])
  end

  it "parses multiple columns with mixed directions" do
    result = parse("SELECT * FROM users ORDER BY active DESC, name ASC")

    expect(result).to eq([
      { column: "active", direction: "desc" },
      { column: "name", direction: "asc" }
    ])
  end

  it "parses ORDER BY followed by LIMIT" do
    result = MysqlParser::Parser.new("SELECT * FROM users ORDER BY id DESC LIMIT 10").parse

    expect(result[:order_by]).to eq([
      { column: "id", direction: "desc" }
    ])
    expect(result[:limit]).to eq("10")
  end

  it "defaults to asc when no direction on multiple columns" do
    result = parse("SELECT * FROM users ORDER BY name, age")

    expect(result).to eq([
      { column: "name", direction: "asc" },
      { column: "age", direction: "asc" }
    ])
  end
end
