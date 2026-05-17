module MysqlParser
  class Parser
    class Where
      include Helpers

      def initialize(lexer)
        @lexer = lexer
      end

      def parse
        parse_conditions
      end

      private

      def parse_conditions
        conditions = []
        conditions << parse_condition

        while and_or?
          joiner = @lexer.advance.downcase
          condition = parse_condition
          condition[:joiner] = joiner if condition.is_a?(Hash)
          conditions << condition
        end

        conditions
      end

      def parse_condition
        if @lexer.current == "("
          if subquery?
            parse_subquery
          else
            @lexer.advance
            result = parse_conditions
            @lexer.advance
            result
          end
        elsif exists_or_not_exists?
          left_side = parse_exists_keyword
          { left_side: left_side, subquery: parse_subquery, right_side: nil }
        else
          left_side = @lexer.advance
          operator = parse_operator
          right_side = parse_right_side(operator)
          { left_side: left_side, operator: operator, right_side: right_side }
        end
      end

      def parse_operator
        two_word = "#{@lexer.current} #{@lexer.peek}".downcase
        if OPERATORS.include?(two_word)
          @lexer.advance
          @lexer.advance
          two_word
        else
          @lexer.advance&.downcase
        end
      end

      def parse_right_side(operator)
        if subquery?
          parse_subquery
        elsif @lexer.current == "("
          collect_until_close
        elsif operator == "between"
          "#{@lexer.advance} #{@lexer.advance} #{@lexer.advance}"
        else
          @lexer.advance
        end
      end

      def collect_until_close
        tokens = [@lexer.advance]
        tokens << @lexer.advance while @lexer.current && tokens.last != ")"
        tokens.join(" ")
      end

      def and_or?
        token = @lexer.current&.downcase
        token == AND || token == OR
      end

      def exists_or_not_exists?
        token = @lexer.current&.downcase
        token == EXISTS || (token == "not" && @lexer.peek&.downcase == EXISTS)
      end

      def parse_exists_keyword
        if @lexer.current&.downcase == "not"
          @lexer.advance
          @lexer.advance
          NOT_EXISTS
        else
          @lexer.advance
          EXISTS
        end
      end
    end
  end
end
