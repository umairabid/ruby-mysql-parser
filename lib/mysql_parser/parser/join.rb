module MysqlParser
  class Parser
    class Join
      include Helpers

      JOIN_PREFIXES = [INNER, LEFT, RIGHT, CROSS].freeze

      def initialize(lexer)
        @lexer = lexer
      end

      def parse
        joins = []

        while join_keyword?
          joins << parse_join
        end

        joins
      end

      private

      def join_keyword?
        token = @lexer.current&.downcase
        token == JOIN || JOIN_PREFIXES.include?(token)
      end

      def parse_join
        join_type = parse_join_type
        table = From.new(@lexer).parse
        on_conditions = parse_on

        { join_type: join_type, table: table, on: on_conditions }
      end

      def parse_join_type
        token = @lexer.current&.downcase

        if JOIN_PREFIXES.include?(token)
          prefix = @lexer.advance.downcase
          @lexer.advance
          "#{prefix} join"
        else
          @lexer.advance
          "join"
        end
      end

      def parse_on
        return unless @lexer.current&.downcase == ON

        @lexer.advance
        Where.new(@lexer).parse
      end
    end
  end
end
