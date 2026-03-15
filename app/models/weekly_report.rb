class WeeklyReport < ApplicationRecord
  belongs_to :user
  has_many :audit_logs, as: :auditable, dependent: :destroy

  validates :period_start, :period_end, presence: true
  validates :period_start, uniqueness: { scope: :user_id }

  scope :recently_modified, -> { order(updated_at: :desc).limit(10) }
  scope :created_this_week, -> { where(created_at: 1.week.ago..) }

  def avg_weight
    BodyWeight.new(avg_weight_g) if avg_weight_g
  end

  def avg_body_fat
    BodyFatRate.new(avg_body_fat_bp) if avg_body_fat_bp
  end

  def total_cal
    Calories.new(total_calories_kcal) if total_calories_kcal
  end

  def formatted_weight
    avg_weight&.formatted || "データなし"
  end

  def formatted_fat
    avg_body_fat&.formatted || "データなし"
  end

  def formatted_calories
    total_cal&.formatted || "データなし"
  end

  def notification_label
    notified_at ? "送信済み #{notified_at.strftime('%m/%d %H:%M')}" : "未送信"
  end

  def formatted_period
    "#{period_start} 〜 #{period_end}"
  end
end
