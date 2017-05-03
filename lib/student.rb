require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'interactive_record.rb'
require "pry"

class Student < InteractiveRecord

  def initialize(options={})
    options.each {|property, value|
      self.send("#{property}=", value)
    }
  end

  def table_name_for_insert
    self.class.table_name
  end

  def self.table_name
    self.to_s.downcase.pluralize
  end


  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    column_names.compact
  end

  self.column_names.each do |column|
    attr_accessor column.to_sym
  end

  def col_names_for_insert
    self.class.column_names.reject{|col_name| col_name == "id"}.join(', ')
  end

  def values_for_insert
    values = []
    self.class.column_names.each {|col| values << "'#{send(col)}'" unless send(col).nil? }
    values.join(', ')
  end

  def save
    insert_sql = "INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert}) VALUES (#{self.values_for_insert})"
    DB[:conn].execute(insert_sql)
    id_sql = "SELECT last_insert_rowid() FROM #{self.table_name_for_insert}"
    @id = DB[:conn].execute(id_sql)[0][0]
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

  def self.find_by(attribute)
    #

    find_key, find_value = nil, nil
    attribute.each {|key, value| find_key, find_value = key, value }
    #binding.pry
    sql = "SELECT * FROM #{self.table_name} WHERE #{find_key} = '#{find_value}'"
    DB[:conn].execute(sql)
  end

end
