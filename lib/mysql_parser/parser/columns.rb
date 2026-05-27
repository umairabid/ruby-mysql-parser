# frozen_string_literal: true

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
          @lexer.advance unless @lexer.keyword?
          skip_comma
        end
        columns
      end

      private

      def parse_column
        return { column_name: @lexer.current, column_alias: parse_alias } if plain_column?
        
        is_distinct = distinct?
        res = if distinct?
                parse_distinct
              elsif aggregate?
                parse_aggregate
              else
                parse_subquery
              end
        unless is_distinct
        @lexer.advance if @lexer.peek.downcase == AS
        res[:column_alias] = parse_alias
        end
        res
      end

      def parse_alias
        return unless @lexer.current&.downcase == AS

        @lexer.advance
        @lexer.advance
      end

      def parse_aggregate
        parent = { type: :aggregate, aggregate: @lexer.current.downcase, columns: [] }
        @lexer.advance 
        while @lexer.current && @lexer.current != ')' && !@lexer.keyword?
          @lexer.advance if @lexer.current == '('
          parent[:columns] << parse_column
          @lexer.advance unless @lexer.current == ')' || @lexer.keyword?
          skip_comma
        end
        parent
      end

      def parse_distinct
        @lexer.advance
        parent = { type: :distinct, columns: [] }
        while @lexer.current && !@lexer.keyword?
          parent[:columns] << parse_column
          @lexer.advance unless @lexer.keyword?
          skip_comma
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

      def plain_column?
        !aggregate? && !distinct? && !subquery?
      end
    end
  end
end
