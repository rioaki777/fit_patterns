class WeightEntry < ApplicationRecord
  include Trackable

  belongs_to :user

  validates :recorded_on, presence: true
  validates :weight_g, presence: true,
                       numericality: { only_integer: true, greater_than_or_equal_to: 20_000, less_than_or_equal_to: 300_000 }
  validates :body_fat_bp, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10_000 },
                          allow_nil: true

  validates :recorded_on, uniqueness: { scope: :user_id }

  validate :recorded_on_is_not_in_future

  scope :recent, -> { order(recorded_on: :desc) }
  scope :between_dates, ->(from, to) { where(recorded_on: from..to) }

  def weight_kg
    weight_g / 1000.0
  end

  def body_fat_percent
    return nil if body_fat_bp.nil?
    body_fat_bp / 100.0
  end

  private

  def recorded_on_is_not_in_future
    return if recorded_on.blank?
    errors.add(:recorded_on, "は未来日を指定できません") if recorded_on > Date.current
  end
end
