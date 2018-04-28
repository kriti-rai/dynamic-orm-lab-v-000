require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    column_names = []

    columns = DB[:conn].execute("PRAGMA table_info(#{table_name})")

    columns.collect do |column|
      column_names << column["name"]
    end

    column_names.compact
  end

  def initialize(hash={})
    hash.each do |k,v|
      self.send("#{k}=", v)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if{|col_name| col_name == "id"}.join(", ")
  end

  def values_for_insert
    values = []
    self.class.column_names.each{|col_name| values << "'#{send(col_name)}'" unless send(col_name).nil?}
    values.join(", ")
  end

  def save
    sql = <<-SQL
      INSERT INTO #{table_name_for_insert}
      (#{col_names_for_insert})
      VALUES (#{values_for_insert})
    SQL

    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid () FROM #{table_name_for_insert}")[0][0]

  end

  def self.find_by_name(name)
    DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = '#{name}'")
  end

  def self.find_by(attr)
    col_name = attr.keys[0].to_s
    value = attr.values[0]

    DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE #{col_name} = '#{value}'")
  end

end
