class GenerateWeeklyReportWorkflow
  def self.call(user:, form:)
    new(user:, form:).call
  end

  def initialize(user:, form:)
    @user = user
    @form = form
  end

  def call
    ActiveSupport::Notifications.instrument("weekly_report.generate") do
      ActiveRecord::Base.transaction do
        stats  = WeeklyReport::Generate.call(user: @user, period: @form.period)
        report = WeeklyReport.create!(
          user: @user,
          **stats,
          period_start: @form.period.start_date,
          period_end:   @form.period.end_date
        )
        SendWeeklyReportJob.perform_later(report.id, @form.notification_channel)
        report
      end
    end
  end
end
