require_relative '../lib/active_record_lite'

# https://tomafro.net/2010/01/tip-relative-paths-with-file-expand-path
cats_db_file_name =
  File.expand_path(File.join(File.dirname(__FILE__), "cats.db"))
DBConnection.open(cats_db_file_name)

class Cat < SQLObject
  set_table_name("cats")
  set_attrs(:id, :name, :owner_id)

  belongs_to :human, :class_name => "Human", :primary_key => :id, :foreign_key => :owner_id
  has_one_through :house, :human, :house
end

class Human < SQLObject
  set_table_name("humans")
  set_attrs(:id, :fname, :lname, :house_id)

  has_many :cats, :foreign_key => :owner_id
  belongs_to :house
end

class House < SQLObject
  set_table_name("houses")
  set_attrs(:id, :address, :house_id)
  has_many :livers, :class_name => "Human", :foreign_key => :house_id
  has_many_through :cats, :livers, :cats
end

class Car < SQLObject
  set_table_name("cars")
  set_attrs(:id, :name, :owner_id)
  belongs_to :owner, :class_name => "Human"
  has_many_through :cats, :owner, :cats
end

cat = Cat.find(1)
p cat
p "Cat Human: #{cat.human}"
p Cat.assoc_params

human = Human.find(1)
p "Human cats: #{human.cats}"
p "Human house: #{human.house}"

p "Cat Human house: #{cat.human.house.id}"
p "Cat house: #{cat.house}"

house = House.find(1)
p "House people: #{house.livers}"
p "House cats: #{house.cats}"

car = Car.find(1)
p "Car person: #{car.owner}"
p "Car cats: #{car.cats}"