require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'

class SQLObject < MassObject

  extend Searchable

  def self.set_table_name(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name
  end

  def self.all
    rows = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{@table_name}
    SQL
    p rows

    self.parse_all(rows)
  end

  def self.find(id)
    row = DBConnection.execute(<<-SQL, id)
      SELECT *
      FROM #{@table_name}
      WHERE id = ?
    SQL
    self.parse_all(row)
  end

  def save
    self.id.nil? ? self.create : self.update
  end

  # protected
 #
 #  def self.objects_from_query_results(query_results)
 #    if query_results.kind_of?(Array)
 #      query_results.map { |row| self.object_from_row(row) }
 #    else
 #      self.object_from_row(query_results)
 #    end
 #  end
 #
 #
 #  def self.object_from_row(row)
 #    sym_keys = row.inject({}) { |hash, (key, val)| hash[key.to_sym] = val; hash }
 #    self.new(sym_keys)
 #  end

  private

  def create
    attr_string = self.attr_hash.keys.join(", ")
    value_string = self.attr_hash.keys.map{ |key| ":#{key}" }.join(", ")

    DBConnection.execute(<<-SQL, self.attr_hash)
      INSERT INTO #{ self.class.table_name }
        (#{ attr_string })
      VALUES
        (#{ value_string })
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    updated_values = self.class.attributes
                       .map { |attr| "#{ attr } = :#{ attr }" }
                       .join(", ")

    DBConnection.execute(<<-SQL, attr_hash)
      UPDATE #{ self.class.table_name }
      SET #{ updated_values }
      WHERE id = :id
    SQL
  end

  def attr_hash
    attrs = {}

    self.class.attributes.each { |attr| attrs[attr] = self.send(attr) }

    attrs
  end

end
