module MysqlParser
  class Parser
    class Columns
      include Helpers

      def initialize(lexer)
        @lexer = lexer
      end

      def parse
        columns = []
        distinct = parse_distinct

        while @lexer.current && !@lexer.keyword?
          columns << parse_column
          skip_comma
        end

        columns.first[:aggregate] = "distinct" if distinct && columns.any?

        columns
      end

      private

      def parse_column
        aggregate = parse_aggregate

        column_name = if subquery?
          parse_subquery
        else
          @lexer.advance
        end

        @lexer.advance if aggregate && @lexer.current == ")"

        column_alias = parse_alias

        { column_name: column_name, column_alias: column_alias, aggregate: aggregate }
      end

      def parse_alias
        return unless @lexer.current&.downcase == AS

        @lexer.advance
        @lexer.advance
      end

      def parse_aggregate
        return unless AGGREGATE_FUNCTIONS.include?(@lexer.current&.downcase) && @lexer.peek == "("

        func = @lexer.advance.downcase
        @lexer.advance
        func
      end

      def parse_distinct
        return false unless @lexer.current&.downcase == "distinct"

        @lexer.advance
        true
      end

      def skip_comma
        @lexer.advance if @lexer.current == ","
      end
    end
  end
end
