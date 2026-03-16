class WeeklyReport::Generate
  def self.call(user:, start_date:, end_date:)
    new(user:, start_date:, end_date:).call
  end

  def initialize(user:, start_date:, end_date:)
    @user = user
    @start_date = start_date
    @end_date = end_date
  end

  def call
    weight_entries = WeightEntry.where(user: @user)
                                .where(recorded_on: @start_date..@end_date)
                                .order(recorded_on: :asc)
    workouts = Workout.where(user: @user)
                      .where(recorded_on: @start_date..@end_date)
                      .order(recorded_on: :asc)

    {
      avg_weight_g:        calc_avg_weight(weight_entries),
      avg_body_fat_bp:     calc_avg_body_fat(weight_entries),
      total_calories_kcal: workouts.sum(:calories_kcal),
      total_workout_min:   workouts.sum(:duration_min)
    }
  end

  private

  def calc_avg_weight(entries)
    return nil if entries.empty?
    (entries.sum(:weight_g) / entries.count.to_f).round
  end

  def calc_avg_body_fat(entries)
    with_fat = entries.where.not(body_fat_bp: nil)
    return nil if with_fat.empty?
    (with_fat.sum(:body_fat_bp) / with_fat.count.to_f).round
  end
end
