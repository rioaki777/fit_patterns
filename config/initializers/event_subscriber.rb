ActiveSupport::Notifications.subscribe("weekly_report.generate") do |event|
  Rails.logger.info "[Event] weekly_report.generate: #{event.payload.inspect} (#{event.duration.round(2)}ms)"
end

ActiveSupport::Notifications.subscribe("weekly_report.notified") do |event|
  Rails.logger.info "[Event] weekly_report.notified: #{event.payload.inspect}"
end
