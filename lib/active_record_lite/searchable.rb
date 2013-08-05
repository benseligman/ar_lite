require_relative './db_connection'

module Searchable
  def where(params)
    p self
    conditions = params.map { |key, _| "#{ key } = :#{ key }" }.join(" AND ")

    rows = DBConnection.execute(<<-SQL, params)
      SELECT *
      FROM #{ self.table_name }
      WHERE #{ conditions }
    SQL

    self.parse_all(rows)
  end

  protected


end