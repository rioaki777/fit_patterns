class BodyFatRate
  attr_reader :basis_points

  def initialize(basis_points)
    @basis_points = basis_points
    freeze
  end

  def to_percent
    basis_points / 100.0
  end

  def formatted
    "#{to_percent}%"
  end

  def ==(other)
    other.is_a?(BodyFatRate) && basis_points == other.basis_points
  end
end
