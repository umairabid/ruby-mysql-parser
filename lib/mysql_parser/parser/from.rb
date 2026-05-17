module MysqlParser
  class Parser
    class From
      include Helpers

      def initialize(lexer)
        @lexer = lexer
      end

      def parse
        name = if subquery?
          parse_subquery
        else
          @lexer.advance
        end

        from_alias = parse_alias

        { name: name, alias: from_alias }
      end

      private

      def parse_alias
        return unless @lexer.current&.downcase == AS

        @lexer.advance
        @lexer.advance
      end
    end
  end
end
