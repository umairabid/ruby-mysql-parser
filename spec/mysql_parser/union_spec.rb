RSpec.describe "UNION" do
  it "parses UNION between two selects" do
    result = MysqlParser.parse("SELECT id FROM users UNION SELECT id FROM admins")

    expect(result[:union].length).to eq(2)
    expect(result[:union][0][:from]).to eq({ name: "users", alias: nil })
    expect(result[:union][0]).not_to have_key(:union_type)
    expect(result[:union][1][:from]).to eq({ name: "admins", alias: nil })
    expect(result[:union][1][:union_type]).to eq("union")
  end

  it "parses UNION ALL" do
    result = MysqlParser.parse("SELECT id FROM users UNION ALL SELECT id FROM admins")

    expect(result[:union][1][:union_type]).to eq("union all")
  end

  it "parses three chained unions" do
    sql = "SELECT id FROM users UNION SELECT id FROM admins UNION ALL SELECT id FROM guests"
    result = MysqlParser.parse(sql)

    expect(result[:union].length).to eq(3)
    expect(result[:union][0][:from]).to eq({ name: "users", alias: nil })
    expect(result[:union][1][:union_type]).to eq("union")
    expect(result[:union][1][:from]).to eq({ name: "admins", alias: nil })
    expect(result[:union][2][:union_type]).to eq("union all")
    expect(result[:union][2][:from]).to eq({ name: "guests", alias: nil })
  end

  it "returns plain hash when no union" do
    result = MysqlParser.parse("SELECT id FROM users")

    expect(result).not_to have_key(:union)
    expect(result[:from]).to eq({ name: "users", alias: nil })
  end
end
