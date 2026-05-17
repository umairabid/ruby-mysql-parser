module MysqlParser
  class Lexer
    def initialize(sql)
      normalized = sql.gsub(/([(),])/, ' \1 ').strip
      @tokens = normalized.split(/\s+/)
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

    def keyword?
      TOKENS.include?(current&.downcase)
    end
  end
end
