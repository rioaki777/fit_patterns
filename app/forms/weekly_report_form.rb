class WeeklyReportForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :period_start, :date
  attribute :period_end,   :date
  attribute :notification_channel, :string, default: "email"

  validates :period_start, :period_end, :notification_channel, presence: true
  validates_with SafePeriodValidator

  def period
    Period.new(start_date: period_start, end_date: period_end)
  end
end
