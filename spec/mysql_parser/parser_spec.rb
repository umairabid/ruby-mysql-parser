RSpec.describe MysqlParser::Parser do
  describe "#parse" do
    it "parses SELECT * FROM users" do
      result = MysqlParser::Parser.new("SELECT * FROM users").parse

      expect(result[:select]).to eq([{ column_name: "*", column_alias: nil, aggregate: nil }])
      expect(result[:from]).to eq({ name: "users", alias: nil })
    end

    it "parses columns with aliases" do
      result = MysqlParser::Parser.new("SELECT id AS user_id, name FROM users").parse

      expect(result[:select]).to eq([
        { column_name: "id", column_alias: "user_id", aggregate: nil },
        { column_name: "name", column_alias: nil, aggregate: nil }
      ])
    end

    it "parses FROM with alias" do
      result = MysqlParser::Parser.new("SELECT * FROM users AS u").parse

      expect(result[:from]).to eq({ name: "users", alias: "u" })
    end

    it "parses subquery in FROM" do
      result = MysqlParser::Parser.new("SELECT * FROM (SELECT id, name, email FROM users)").parse

      expect(result[:select]).to eq([{ column_name: "*", column_alias: nil, aggregate: nil }])
      expect(result[:from][:name][:select]).to eq([
        { column_name: "id", column_alias: nil, aggregate: nil },
        { column_name: "name", column_alias: nil, aggregate: nil },
        { column_name: "email", column_alias: nil, aggregate: nil }
      ])
      expect(result[:from][:name][:from]).to eq({ name: "users", alias: nil })
      expect(result[:from][:alias]).to be_nil
    end

    it "parses subquery in FROM with alias" do
      result = MysqlParser::Parser.new("SELECT * FROM (SELECT id FROM users) AS subq").parse

      expect(result[:from][:name][:select]).to eq([{ column_name: "id", column_alias: nil, aggregate: nil }])
      expect(result[:from][:alias]).to eq("subq")
    end

    it "parses subquery as a column with alias" do
      result = MysqlParser::Parser.new(
        "SELECT (SELECT constant FROM constants LIMIT 1) AS my_constant, id FROM users"
      ).parse

      expect(result[:select].length).to eq(2)
      expect(result[:select][0][:column_name][:select]).to eq([{ column_name: "constant", column_alias: nil, aggregate: nil }])
      expect(result[:select][0][:column_name][:from]).to eq({ name: "constants", alias: nil })
      expect(result[:select][0][:column_name][:limit]).to eq("1")
      expect(result[:select][0][:column_alias]).to eq("my_constant")
      expect(result[:select][1]).to eq({ column_name: "id", column_alias: nil, aggregate: nil })
      expect(result[:from]).to eq({ name: "users", alias: nil })
    end
  end
end
