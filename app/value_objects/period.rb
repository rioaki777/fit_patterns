class Period
  attr_reader :start_date, :end_date

  def initialize(start_date:, end_date:)
    @start_date = start_date
    @end_date = end_date
    freeze
  end

  def self.current_week
    new(start_date: Date.current.beginning_of_week, end_date: Date.current.end_of_week)
  end

  def days
    (end_date - start_date).to_i + 1
  end

  def covers?(date)
    to_range.cover?(date)
  end

  def to_range
    start_date..end_date
  end

  def ==(other)
    other.is_a?(Period) && start_date == other.start_date && end_date == other.end_date
  end
end
