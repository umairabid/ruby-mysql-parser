# frozen_string_literal: true

RSpec.describe 'Columns Parser' do
  def parse(sql)
    MysqlParser::Parser.new(sql).parse[:select]
  end

  it 'parses aggregate function' do
    result = parse('SELECT COUNT(*) FROM users')

    expect(result).to eq([
      { type: :aggregate, aggregate: 'count', column_alias: nil,
        columns: [{ column_name: '*', column_alias: nil }] }
    ])
  end

  it 'parses aggregate with alias' do
    result = parse('SELECT AVG(price) AS avg_price FROM products')

    expect(result).to eq([
      { type: :aggregate, aggregate: 'avg', column_alias: 'avg_price',
        columns: [{ column_name: 'price', column_alias: nil }] }
    ])
  end

  it 'parses mix of aggregate and plain columns' do
    result = parse('SELECT id, COUNT(*) AS total, name FROM users')

    expect(result).to eq([
      { column_name: 'id', column_alias: nil },
      { type: :aggregate, aggregate: 'count', column_alias: 'total',
        columns: [{ column_name: '*', column_alias: nil }] },
      { column_name: 'name', column_alias: nil }
    ])
  end

  context 'when using distinct' do
    it 'parses distinct on one column' do
      sql = 'SELECT DISTINCT name FROM users'
      result = parse(sql)

      expect(result).to eq([
        { type: :distinct, column_alias: nil,
          columns: [{ column_name: 'name', column_alias: nil }] }
      ])
    end

    it 'parses distinct on multiple columns' do
      sql = 'SELECT DISTINCT name, age FROM users'
      result = parse(sql)

      expect(result).to eq([
        { type: :distinct, column_alias: nil,
          columns: [{ column_name: 'name', column_alias: nil }, { column_name: 'age', column_alias: nil }] }
      ])
    end

    it 'parses weird distinct aggregate combination' do
      sql = 'select distinct count(name), sum(id), name from users'
      result = parse(sql)

      expect(result).to eq([
        {
          type: :distinct,
          column_alias: nil,
          columns: [
            { type: :aggregate, aggregate: 'count', column_alias: nil,
              columns: [{ column_name: 'name', column_alias: nil }] },
            { type: :aggregate, aggregate: 'sum', column_alias: nil,
              columns: [{ column_name: 'id', column_alias: nil }] },
            { column_name: 'name', column_alias: nil }
          ]
        }
      ])
    end

    it 'parses nested aggregates with distincts' do
      sql = 'select count(distinct name), sum(distinct id, name), name from users'
      result = parse(sql)

      expect(result).to eq([
        {
          type: :aggregate,
          aggregate: 'count',
          column_alias: nil,
          columns: [{ type: :distinct, column_alias: nil,
                      columns: [{ column_name: 'name', column_alias: nil }] }]
        },
        {
          type: :aggregate,
          aggregate: 'sum',
          column_alias: nil,
          columns: [{ type: :distinct, column_alias: nil,
                      columns: [{ column_name: 'id', column_alias: nil }, { column_name: 'name', column_alias: nil }] }]
        },
        { column_name: 'name', column_alias: nil }
      ])
    end

    it 'parses nested aggregates with distincts and aliases' do
      sql = 'select count(distinct name) as uniq_name, sum(distinct id, name) as uniq_id, name from users'
      result = parse(sql)

      expect(result).to eq([
        {
          type: :aggregate,
          aggregate: 'count',
          column_alias: 'uniq_name',
          columns: [{ type: :distinct, column_alias: nil,
                      columns: [{ column_name: 'name', column_alias: nil }] }]
        },
        {
          type: :aggregate,
          aggregate: 'sum',
          column_alias: 'uniq_id',
          columns: [{ type: :distinct, column_alias: nil,
                      columns: [{ column_name: 'id', column_alias: nil }, { column_name: 'name', column_alias: nil }] }]
        },
        { column_name: 'name', column_alias: nil }
      ])
    end
  end
end
