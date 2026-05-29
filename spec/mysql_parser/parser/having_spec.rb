# frozen_string_literal: true

RSpec.describe 'HAVING' do
  it 'parses simple condition' do
    sql = 'SELECT department_id FROM users GROUP BY department_id HAVING department_id > 10'
    result = MysqlParser.parse(sql)

    expect(result[:having]).to eq([
      { left_side: 'department_id', operator: '>', right_side: '10' }
    ])
  end

  it 'parses AND conditions' do
    sql = 'SELECT department_id FROM users GROUP BY department_id HAVING department_id > 10 AND count > 1'
    result = MysqlParser.parse(sql)

    expect(result[:having]).to eq([
      { left_side: 'department_id', operator: '>', right_side: '10' },
      { joiner: 'and', left_side: 'count', operator: '>', right_side: '1' }
    ])
  end
end
