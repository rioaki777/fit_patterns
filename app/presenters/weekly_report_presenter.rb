class WeeklyReportPresenter
  delegate :id, :user, :period_start, :period_end, :notified_at, to: :@report

  def initialize(report)
    @report = report
  end

  def formatted_period
    "#{period_start} 〜 #{period_end}"
  end

  def formatted_weight
    @report.avg_weight_g ? "#{@report.avg_weight_g / 1000.0} kg" : "データなし"
  end

  def formatted_fat
    @report.avg_body_fat_bp ? "#{@report.avg_body_fat_bp / 100.0}%" : "データなし"
  end

  def formatted_calories
    @report.total_calories_kcal ? "#{@report.total_calories_kcal} kcal" : "データなし"
  end

  def notified?
    @report.notified_at.present?
  end

  def notification_label
    notified? ? "送信済み #{notified_at.strftime('%m/%d %H:%M')}" : "未送信"
  end
end
