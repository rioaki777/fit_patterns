class WeeklyReportMailer < ApplicationMailer
  def report_ready(report)
    @report = report
    mail(to: report.user.email, subject: "週次レポートが生成されました")
  end
end
