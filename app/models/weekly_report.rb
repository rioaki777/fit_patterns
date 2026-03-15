class WeeklyReport < ApplicationRecord
  include Trackable

  belongs_to :user
  has_many :audit_logs, as: :auditable, dependent: :destroy

  validates :period_start, :period_end, presence: true
  validates :period_start, uniqueness: { scope: :user_id }

  after_commit :write_audit_log, on: [:create, :update]

  def avg_weight
    BodyWeight.new(avg_weight_g) if avg_weight_g
  end

  def avg_body_fat
    BodyFatRate.new(avg_body_fat_bp) if avg_body_fat_bp
  end

  def total_cal
    Calories.new(total_calories_kcal) if total_calories_kcal
  end

  private

  def write_audit_log
    AuditLog.create!(
      auditable: self,
      event: "weekly_report_#{saved_change_to_id? ? 'created' : 'updated'}",
      user_id: user_id,
      payload: { period_start:, period_end:, notified_at: }
    )
  end
end
