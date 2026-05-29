module MysqlParser
  class Parser
    class OrderBy
      include Helpers

      def initialize(lexer)
        @lexer = lexer
      end

      def parse
        columns = []

        loop do
          column = parse_column
          direction = parse_direction

          columns << { column: column, direction: direction }

          break unless @lexer.current == ","

          @lexer.advance
        end

        columns
      end

      private

      def parse_column
        if aggregate_function?
          name = @lexer.advance
          "#{name}#{collect_until_close}"
        else
          @lexer.advance
        end
      end

      def aggregate_function?
        AGGREGATE_FUNCTIONS.include?(@lexer.current&.downcase) && @lexer.peek == '('
      end

      def collect_until_close
        tokens = [@lexer.advance] # (
        depth = 1
        while @lexer.current && depth > 0
          token = @lexer.advance
          depth += 1 if token == "("
          depth -= 1 if token == ")"
          tokens << token
        end
        tokens.join("")
      end

      def parse_direction
        token = @lexer.current&.downcase
        return "asc" unless token == ASC || token == DESC

        @lexer.advance.downcase
      end
    end
  end
end
