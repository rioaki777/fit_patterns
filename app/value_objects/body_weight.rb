class BodyWeight
  attr_reader :grams

  def initialize(grams)
    @grams = grams
    freeze
  end

  def to_kg
    grams / 1000.0
  end

  def formatted
    "#{to_kg} kg"
  end

  def ==(other)
    other.is_a?(BodyWeight) && grams == other.grams
  end
end
