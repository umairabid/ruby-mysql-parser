# frozen_string_literal: true

RSpec.describe 'GROUP BY' do
  it 'parses single column' do
    sql = 'SELECT count(*) FROM users GROUP BY department_id'
    result = MysqlParser.parse(sql)

    expect(result[:group_by]).to eq(['department_id'])
  end

  it 'parses multiple columns' do
    sql = 'SELECT count(*) FROM users GROUP BY department_id, role'
    result = MysqlParser.parse(sql)

    expect(result[:group_by]).to eq(['department_id', 'role'])
  end

  it 'parses GROUP BY followed by ORDER BY' do
    sql = 'SELECT id FROM users GROUP BY department_id ORDER BY id DESC'
    result = MysqlParser.parse(sql)

    expect(result[:group_by]).to eq(['department_id'])
    expect(result[:order_by]).to eq([{ column: 'id', direction: 'desc' }])
  end
end
