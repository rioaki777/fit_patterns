class Calories
  attr_reader :kcal

  def initialize(kcal)
    @kcal = kcal
    freeze
  end

  def formatted
    "#{kcal} kcal"
  end

  def +(other)
    Calories.new(kcal + other.kcal)
  end

  def ==(other)
    other.is_a?(Calories) && kcal == other.kcal
  end
end
