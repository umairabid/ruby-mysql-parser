module MysqlParser
  class Parser
    def initialize(sql)
      @lexer = Lexer.new(sql)
    end

    def parse
      first = parse_select

      return first unless @lexer.current&.downcase == UNION

      queries = [first]

      while @lexer.current&.downcase == UNION
        @lexer.advance
        union_type = if @lexer.current&.downcase == ALL
          @lexer.advance
          "union all"
        else
          "union"
        end

        query = parse_select
        query[:union_type] = union_type
        queries << query
      end

      { union: queries }
    end

    private

    def parse_select
      result = {}

      while @lexer.current && @lexer.current.downcase != UNION
        case current_keyword
        when "select"
          @lexer.advance
          result[:select] = Columns.new(@lexer).parse
        when "from"
          @lexer.advance
          result[:from] = From.new(@lexer).parse
        when "join", "inner", "left", "right", "cross"
          result[:joins] = Join.new(@lexer).parse
        when "where"
          @lexer.advance
          result[:where] = Where.new(@lexer).parse
        when "order"
          @lexer.advance
          @lexer.advance if @lexer.current&.downcase == "by"
          result[:order_by] = OrderBy.new(@lexer).parse
        when "group"
          @lexer.advance
          @lexer.advance if @lexer.current&.downcase == "by"
          result[:group_by] = GroupBy.new(@lexer).parse
        when "having"
          @lexer.advance
          result[:having] = Having.new(@lexer).parse
        when "limit"
          @lexer.advance
          result[:limit] = @lexer.advance
        else
          @lexer.advance
        end
      end

      result
    end

    private

    def current_keyword
      @lexer.current&.downcase if @lexer.keyword?
    end
  end
end
