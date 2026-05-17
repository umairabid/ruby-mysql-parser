module MysqlParser
  class Parser
    class OrderBy
      def initialize(lexer)
        @lexer = lexer
      end

      def parse
        columns = []

        loop do
          column = @lexer.advance
          direction = parse_direction

          columns << { column: column, direction: direction }

          break unless @lexer.current == ","

          @lexer.advance
        end

        columns
      end

      private

      def parse_direction
        token = @lexer.current&.downcase
        return "asc" unless token == ASC || token == DESC

        @lexer.advance.downcase
      end
    end
  end
end
