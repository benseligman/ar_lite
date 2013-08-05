class MassObject
  def self.set_attrs(*attributes)
    @attributes = attributes

    attributes.each { |attribute|  attr_accessor attribute }
    nil
  end

  def self.attributes
    @attributes
  end

  def self.parse_all(results)
    if results.kind_of?(Array)
      results.map { |row| self.object_from_row(row) }
    else
      self.object_from_row(results)
    end
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      unless self.class.attributes.include?(attr_name)
        raise "mass assignment to unregistered attribute #{attr_name}"
      end

      self.send("#{attr_name}=", value)
    end
  end

  private

  def self.object_from_row(row)
    sym_keys = row.inject({}) { |hash, (attr, val)| hash[attr.to_sym] = val; hash }
    self.new(sym_keys)
  end
end
