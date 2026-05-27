# frozen_string_literal: true

module MysqlParser
  class Parser
    class Columns
      include Helpers

      def initialize(lexer)
        @lexer = lexer
        @global_distinct = @lexer.current&.downcase == DISTINCT
      end

      def parse
        columns = []
        while @lexer.current && !@lexer.keyword?
          columns << parse_column
          @lexer.advance unless @lexer.keyword?
          skip_comma
        end
        columns
      end

      private

      def parse_column
        current = @lexer.current
        puts "parse_column: #{@lexer.current}"
        is_distinct = distinct?
        res = if is_distinct
          parse_distinct
        elsif aggregate?
          parse_aggregate
        elsif subquery?
          parse_subquery
        else
          { column_name: @lexer.current }
        end
        puts 'AS' == AS
        puts "is_distinct: #{is_distinct}"
        puts "parsed_column: #{current}, result: #{res.inspect}"
        puts "cursor after parsing column: #{@lexer.current}"
        unless is_distinct
          res[:column_alias] = parse_alias
        end
        res
      end

      def parse_alias
        puts "lexer.peek: #{@lexer.peek}, lexer.peek_keyword?: #{@lexer.peek_keyword?}, lexer.peek != AS: #{@lexer.peek != AS}, lexer.peek == ')': #{@lexer.peek == ')'}"
        return if @lexer.peek == ',' || (@lexer.peek_keyword? && @lexer.peek != AS) || @lexer.peek == ')'

        
        @lexer.advance if @lexer.peek.downcase == AS
        puts "before alias advance: #{@lexer.current}"
        @lexer.advance 
        puts "after alias advance: #{@lexer.current}"
        @lexer.current
      end

      def parse_aggregate
        parent = { type: :aggregate, aggregate: @lexer.current.downcase, columns: [] }
        @lexer.advance
        while @lexer.current && @lexer.current != ')' && !@lexer.keyword?
          @lexer.advance if @lexer.current == '('
          parent[:columns] << parse_column
          puts "agg after parse column: #{@lexer.current}"
          @lexer.advance unless @lexer.current == ')' || @lexer.keyword?
        end
        parent
      end

      def parse_distinct
        @lexer.advance
        parent = { type: :distinct, columns: [] }
        while @lexer.current && !terminate_distinct?
          puts "parse_distinct loop: #{@lexer.current}"
          skip_comma
          parsed_column = parse_column
          parent[:columns] << parsed_column
          @lexer.advance unless terminate_distinct?
        end
        parent
      end

      def skip_comma
        @lexer.advance if @lexer.current == ','
      end

      def aggregate?
        AGGREGATE_FUNCTIONS.include?(@lexer.current&.downcase) && @lexer.peek == '('
      end

      def distinct?
        @lexer.current&.downcase == 'distinct'
      end

      def terminate_distinct?
        @global_distinct ? @lexer.keyword? : @lexer.current == ')'
      end

      def plain_column?
        !aggregate? && !distinct? && !subquery?
      end
    end
  end
end
