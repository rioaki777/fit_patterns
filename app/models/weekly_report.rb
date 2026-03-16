class WeeklyReport < ApplicationRecord
  belongs_to :user
  has_many :audit_logs, as: :auditable, dependent: :destroy

  validates :period_start, :period_end, presence: true
  validates :period_start, uniqueness: { scope: :user_id }

  scope :recently_modified, -> { order(updated_at: :desc).limit(10) }
  scope :created_this_week, -> { where(created_at: 1.week.ago..) }

  after_commit :write_audit_log, on: [ :create, :update ]

  def formatted_weight
    avg_weight_g ? "#{avg_weight_g / 1000.0} kg" : "データなし"
  end

  def formatted_fat
    avg_body_fat_bp ? "#{avg_body_fat_bp / 100.0}%" : "データなし"
  end

  def formatted_calories
    total_calories_kcal ? "#{total_calories_kcal} kcal" : "データなし"
  end

  def notification_label
    notified_at ? "送信済み #{notified_at.strftime('%m/%d %H:%M')}" : "未送信"
  end

  def formatted_period
    "#{period_start} 〜 #{period_end}"
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
