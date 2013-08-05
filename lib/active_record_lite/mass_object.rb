class MassObject
  def self.set_attrs(*attributes)
    @attributes = attributes
    attrs.each do |attr|
      define_method(attr) { attr }
      define_method("#{attr}=(val)") { attr = val }
    end
  end

  def self.attributes

  end

  def self.parse_all(results)
  end

  def initialize(params = {})
  end
end
