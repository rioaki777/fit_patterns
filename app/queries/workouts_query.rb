class WorkoutsQuery
  def self.call(user:, period:)
    new(user:, period:).call
  end

  def initialize(user:, period:)
    @user = user
    @period = period
  end

  def call
    Workout.where(user: @user)
           .between_dates(@period.start_date, @period.end_date)
           .order(recorded_on: :asc)
  end
end
