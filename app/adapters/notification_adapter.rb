class NotificationAdapter
  def self.for(channel)
    case channel
    when "email" then MailNotificationAdapter.new
    when "slack"  then SlackNotificationAdapter.new
    else raise ArgumentError, "Unknown channel: #{channel}"
    end
  end

  def deliver(report:)
    raise NotImplementedError, "#{self.class}#deliver is not implemented"
  end
end
