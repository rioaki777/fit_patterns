class MailNotificationAdapter < NotificationAdapter
  def deliver(report:)
    WeeklyReportMailer.report_ready(report).deliver_later
  end
end
