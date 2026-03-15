class SlackNotificationAdapter < NotificationAdapter
  def deliver(report:)
    Rails.logger.info "[Slack] Weekly report ready: #{report.id}"
  end
end
