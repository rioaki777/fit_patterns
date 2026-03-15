class SendWeeklyReportJob < ApplicationJob
  queue_as :default

  def perform(weekly_report_id, channel)
    report  = WeeklyReport.find(weekly_report_id)
    adapter = NotificationAdapter.for(channel)
    adapter.deliver(report:)
    report.update!(notified_at: Time.current)

    ActiveSupport::Notifications.instrument("weekly_report.notified",
      report_id: report.id, channel:)
  end
end
