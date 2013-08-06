require "debugger"
require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  def other_class_name
    @params[:class_name] || @name.singularize.camelize
  end

  def other_class
    other_class_name.constantize
  end

  def other_table
    other_class.table_name
  end

  def foreign_key
    @params[:foreign_key] || :"#{@name}_id"
  end

  def primary_key
    @params[:primary_key] || :id
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
    @name = name.to_s
    @params = params
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, self_class, params)
    @name = name.to_s
    @params = params
    @self_class = self_class
  end
end

module Associatable
  def assoc_params
    @assoc_params ||= {}
  end

  def belongs_to(name, params = {})
    aps = BelongsToAssocParams.new(name, params)
    self.assoc_params[name] = aps

    define_method(name) do
      row = DBConnection.execute(<<-SQL, self.id)
        SELECT *
        FROM #{aps.other_table}
        WHERE #{aps.other_table}.#{aps.primary_key} = ?
      SQL

      aps.other_class.parse_all(row.first)
    end
  end

  def has_many(name, params = {})
    aps = HasManyAssocParams.new(name, self.class, params)
    self.assoc_params[name] = aps

    define_method(name) do
      rows = DBConnection.execute(<<-SQL, self.id)
        SELECT *
        FROM #{aps.other_table}
        WHERE #{aps.other_table}.#{aps.foreign_key} = ?
      SQL

      aps.other_class.parse_all(rows)
    end
  end

  def has_one_through(name, assoc1, assoc2)

   define_method(name) do
      through = self.class.assoc_params[assoc1]
      source = through.other_class.assoc_params[assoc2]

      row = DBConnection.execute(<<-SQL, self.send(through.foreign_key).to_s)
        SELECT
          source.*
        FROM
          #{through.other_table} through
        JOIN
          #{source.other_table} source ON through.#{source.foreign_key} = source.#{source.primary_key}
        WHERE
          through.#{through.primary_key} = ?
        SQL

      source.other_class.parse_all(row.first)
    end

  end

  def has_many_through(name, assoc1, assoc2)

    define_method(name) do
      through = self.class.assoc_params[assoc1]
      p through
      source = through.other_class.assoc_params[assoc2]
      p source

      query_snippets = self.class.has_many_through_strings(through, source, self)


      rows = DBConnection.execute(<<-SQL, query_snippets[:insert])
        SELECT
          #{source.other_table}.*
        FROM
          #{ through.other_table }
        JOIN
          #{ source.other_table } ON
          #{ query_snippets[:join] }
        WHERE
          #{ query_snippets[:condition] } = ?
      SQL

      source.other_class.parse_all(rows)
    end

    def has_many_through_strings(through, source, origin)
      params = {}
      if source.kind_of?(HasManyAssocParams)
        params[:join] = <<-SQL
         #{through.other_table}.#{source.primary_key} =
            #{source.other_table}.#{source.foreign_key}
        SQL
      else
        params[:join] = <<-SQL
         #{through.other_table}.#{source.foreign_key} =
            #{source.other_table}.#{source.primary_key}
        SQL
      end

      if through.kind_of?(HasManyAssocParams)
        params[:condition] = " #{through.other_table}.#{through.foreign_key} "
        params[:insert] = origin.id
      else
        params[:condition] =   " #{through.other_table}.#{through.primary_key} "
        params[:insert] = origin.send(through.foreign_key).to_s
      end

      params
    end
  end
end
