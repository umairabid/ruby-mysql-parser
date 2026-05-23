module MysqlParser
  class Parser
    class Columns
      include Helpers

      def initialize(lexer)
        @lexer = lexer
      end

      def parse
        columns = []
        while @lexer.current && !@lexer.keyword?
          columns << parse_column
          skip_comma
        end
        columns
      end

      private

      def parse_column(parent: nil)
        if distinct?
          parse_distinct
        elsif aggregate?
          parse_aggregate
        elsif subquery?
          parse_subquery
        else
          @lexer.advance
        end
        if parent.nil?
          { column_name: column_name, column_alias: column_alias }
        else
          parent[:columns] << { column_name: column_name, column_alias: column_alias }
          parent
        end
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
        @lexer.advance
        @lexer.advance if @lexer.current == "("

        parse_column({ type: :distinct, columns: [] })
      end

      def skip_comma
        @lexer.advance if @lexer.current == ","
      end

      def aggregate?
      end

      def distinct?
        @lexer.current&.downcase == "distinct"
      end
    end
  end
end
