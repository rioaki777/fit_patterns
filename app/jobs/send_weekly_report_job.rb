class SendWeeklyReportJob < ApplicationJob
  queue_as :default

  def perform(weekly_report_id, channel)
    report = WeeklyReport.find(weekly_report_id)

    case channel
    when "email"
      WeeklyReportMailer.report_ready(report).deliver_now
    when "slack"
      Rails.logger.info "[Slack] Weekly report ready: #{report.id}"
    end

    report.update!(notified_at: Time.current)
  end
end
