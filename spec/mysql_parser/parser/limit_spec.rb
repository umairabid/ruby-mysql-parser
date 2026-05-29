# frozen_string_literal: true

RSpec.describe 'LIMIT and OFFSET' do
  it 'parses LIMIT count' do
    sql = 'SELECT * FROM users LIMIT 10'
    result = MysqlParser.parse(sql)

    expect(result[:limit]).to eq('10')
    expect(result[:offset]).to be_nil
  end

  it 'parses LIMIT count OFFSET offset' do
    sql = 'SELECT * FROM users LIMIT 10 OFFSET 5'
    result = MysqlParser.parse(sql)

    expect(result[:limit]).to eq('10')
    expect(result[:offset]).to eq('5')
  end

  it 'parses LIMIT offset, count' do
    sql = 'SELECT * FROM users LIMIT 5, 10'
    result = MysqlParser.parse(sql)

    expect(result[:limit]).to eq('10')
    expect(result[:offset]).to eq('5')
  end

  it 'parses OFFSET independently' do
    # Valid MySQL? Technically OFFSET must follow LIMIT in MySQL, 
    # but some dialects might allow it. We can be flexible.
    sql = 'SELECT * FROM users OFFSET 5'
    result = MysqlParser.parse(sql)

    expect(result[:offset]).to eq('5')
  end
end
