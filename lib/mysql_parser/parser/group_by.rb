# frozen_string_literal: true

module MysqlParser
  class Parser
    class GroupBy
      def initialize(lexer)
        @lexer = lexer
      end

      def parse
        columns = []

        loop do
          columns << @lexer.advance
          break unless @lexer.current == ","

          @lexer.advance
        end

        columns
      end
    end
  end
end
