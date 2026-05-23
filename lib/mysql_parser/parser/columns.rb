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
        puts "came here 1"
        if distinct?
          puts "came here 2"
          parse_distinct
        elsif aggregate?
          parse_aggregate
        elsif subquery?
          parse_subquery
        end
        result = if parent.nil?
          { column_name: @lexer.current, column_alias: parse_alias }
        else
          parent[:columns] << { column_name: @lexer.current, column_alias: parse_alias }
          parent
        end
        @lexer.advance
        result
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
        puts "came here 3"
        @lexer.advance
        @lexer.advance if @lexer.current == "("

        parse_column(parent: { type: :distinct, columns: [] })
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
