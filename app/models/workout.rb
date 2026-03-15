class Workout < ApplicationRecord
  belongs_to :user

  validates :recorded_on, presence: true
  validates :kind, presence: true, length: { maximum: 50 }

  validates :duration_min, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 24 * 60 },
                           allow_nil: true
  validates :calories_kcal, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 20_000 },
                            allow_nil: true
  validates :intensity, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 },
                        allow_nil: true

  validate :recorded_on_is_not_in_future

  scope :recent, -> { order(recorded_on: :desc) }
  scope :between_dates, ->(from, to) { where(recorded_on: from..to) }

  private

  def recorded_on_is_not_in_future
    return if recorded_on.blank?
    errors.add(:recorded_on, "は未来日を指定できません") if recorded_on > Date.current
  end
end
