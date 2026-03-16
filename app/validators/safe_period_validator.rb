class SafePeriodValidator < ActiveModel::Validator
  MAX_DAYS = 31

  def validate(record)
    start_date = record.period_start
    end_date   = record.period_end

    return if start_date.blank? || end_date.blank?

    if start_date > end_date
      record.errors.add(:period_start, "は終了日より前の日付を指定してください")
    end

    if end_date > Date.current
      record.errors.add(:period_end, "は未来日を指定できません")
    end

    if end_date - start_date >= MAX_DAYS
      record.errors.add(:base, "期間は#{MAX_DAYS}日以内にしてください")
    end
  end
end
