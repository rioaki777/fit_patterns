class GenerateWeeklyReportCommand
  Result = Struct.new(:success?, :report, :errors, keyword_init: true)

  def self.call(user:, period_start:, period_end:, channel:)
    new(user:, period_start:, period_end:, channel:).call
  end

  def initialize(user:, period_start:, period_end:, channel:)
    @user = user
    @period_start = period_start
    @period_end = period_end
    @channel = channel
  end

  def call
    errors = validate
    return Result.new(success?: false, report: nil, errors:) if errors.any?

    weight_entries = WeightEntry.where(user: @user)
                                .where(recorded_on: @period_start..@period_end)
                                .order(recorded_on: :asc)
    workouts = Workout.where(user: @user)
                      .where(recorded_on: @period_start..@period_end)
                      .order(recorded_on: :asc)

    avg_weight_g = if weight_entries.any?
      (weight_entries.sum(:weight_g) / weight_entries.count.to_f).round
    end

    with_fat = weight_entries.where.not(body_fat_bp: nil)
    avg_body_fat_bp = if with_fat.any?
      (with_fat.sum(:body_fat_bp) / with_fat.count.to_f).round
    end

    total_calories_kcal = workouts.sum(:calories_kcal)
    total_workout_min   = workouts.sum(:duration_min)

    report = WeeklyReport.create!(
      user:               @user,
      period_start:       @period_start,
      period_end:         @period_end,
      avg_weight_g:,
      avg_body_fat_bp:,
      total_calories_kcal:,
      total_workout_min:
    )

    AuditLog.create!(
      auditable: report,
      event:     "weekly_report_created",
      user_id:   @user.id,
      payload:   { period_start: @period_start, period_end: @period_end, notified_at: nil }
    )

    case @channel
    when "email"
      WeeklyReportMailer.report_ready(report).deliver_now
    when "slack"
      Rails.logger.info "[Slack] Weekly report ready: #{report.id}"
    end

    report.update!(notified_at: Time.current)
    Result.new(success?: true, report:, errors: nil)
  rescue => e
    Result.new(success?: false, report: nil, errors: [e.message])
  end

  private

  def validate
    errors = []
    errors << "開始日を入力してください" if @period_start.nil?
    errors << "終了日を入力してください" if @period_end.nil?

    if @period_start && @period_end
      errors << "開始日は終了日より前の日付を指定してください" if @period_start > @period_end
      errors << "終了日は未来日を指定できません" if @period_end > Date.current
      errors << "期間は31日以内にしてください" if (@period_end - @period_start).to_i >= 31
    end

    errors
  end
end
