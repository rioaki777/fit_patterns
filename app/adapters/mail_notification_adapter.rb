class MailNotificationAdapter < NotificationAdapter
  def deliver(report:)
    WeeklyReportMailer.report_ready(report).deliver_now
  end
end
