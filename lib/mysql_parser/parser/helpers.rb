module MysqlParser
  class Parser
    module Helpers
      private

      def subquery?
        @lexer.current == "(" && @lexer.peek&.downcase == SELECT
      end

      def parse_subquery
        @lexer.advance
        tokens = []
        depth = 1

        while @lexer.current && depth > 0
          if @lexer.current == "("
            depth += 1
          elsif @lexer.current == ")"
            depth -= 1
            if depth == 0
              @lexer.advance
              break
            end
          end
          tokens << @lexer.advance
        end

        Parser.new(tokens.join(" ")).parse
      end
    end
  end
end
