RSpec.describe MysqlParser::Lexer do
  describe "#current and #advance" do
    it "walks through tokens one by one" do
      lexer = MysqlParser::Lexer.new("SELECT * FROM users")

      expect(lexer.current).to eq("SELECT")
      expect(lexer.advance).to eq("SELECT")
      expect(lexer.current).to eq("*")
      expect(lexer.advance).to eq("*")
      expect(lexer.current).to eq("FROM")
    end
  end

  describe "normalization" do
    it "separates commas into their own tokens" do
      lexer = MysqlParser::Lexer.new("id,name,email")

      expect(lexer.advance).to eq("id")
      expect(lexer.advance).to eq(",")
      expect(lexer.advance).to eq("name")
      expect(lexer.advance).to eq(",")
      expect(lexer.advance).to eq("email")
    end

    it "separates parentheses into their own tokens" do
      lexer = MysqlParser::Lexer.new("(SELECT id)")

      expect(lexer.advance).to eq("(")
      expect(lexer.advance).to eq("SELECT")
      expect(lexer.advance).to eq("id")
      expect(lexer.advance).to eq(")")
    end
  end

  describe "#keyword?" do
    it "returns true for known keywords" do
      lexer = MysqlParser::Lexer.new("SELECT")

      expect(lexer.keyword?).to be true
    end

    it "returns true case-insensitively" do
      lexer = MysqlParser::Lexer.new("select")

      expect(lexer.keyword?).to be true
    end

    it "returns false for non-keywords" do
      lexer = MysqlParser::Lexer.new("users")

      expect(lexer.keyword?).to be false
    end
  end
end
