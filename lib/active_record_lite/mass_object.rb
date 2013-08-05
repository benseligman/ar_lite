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
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      unless self.class.attributes.include?(param)
        raise "mass assignment to unregistered attribute #{attr_name}"
      end

      self.send("#{attr_name}=", value)
    end
  end
end
