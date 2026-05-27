module MysqlParser
  class Lexer
    def initialize(sql)
      escaped_spaces = sql.gsub(/'([^']*)'/) { |match| match.gsub(/\s+/, '__SPACE__') }
      normalized = escaped_spaces.gsub(/([(),])/, ' \1 ').strip
      @tokens = normalized.split(/\s+/)
      @tokens.map! { |t| t.gsub('__SPACE__', ' ') }
      @pos = 0
    end

    def current
      @tokens[@pos]
    end

    def advance
      token = @tokens[@pos]
      @pos += 1
      token
    end

    def peek
      @tokens[@pos + 1]
    end

    def peek_keyword?
      TOKENS.include?(peek&.downcase)
    end

    def keyword?
      TOKENS.include?(current&.downcase)
    end
  end
end
