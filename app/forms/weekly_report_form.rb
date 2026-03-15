class WeeklyReportForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :period_start, :date
  attribute :period_end,   :date
  attribute :notification_channel, :string, default: "email"

  validates :period_start, :period_end, :notification_channel, presence: true

  validate :period_dates_are_valid

  private

  def period_dates_are_valid
    return if period_start.blank? || period_end.blank?

    if period_start > period_end
      errors.add(:period_start, "は終了日より前の日付を指定してください")
    end

    if period_end > Date.current
      errors.add(:period_end, "は未来日を指定できません")
    end

    if (period_end - period_start).to_i >= 31
      errors.add(:base, "期間は31日以内にしてください")
    end
  end
end
