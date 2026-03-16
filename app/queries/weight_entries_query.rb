class WeightEntriesQuery
  def self.call(user:, start_date:, end_date:)
    new(user:, start_date:, end_date:).call
  end

  def initialize(user:, start_date:, end_date:)
    @user = user
    @start_date = start_date
    @end_date = end_date
  end

  def call
    WeightEntry.where(user: @user)
               .where(recorded_on: @start_date..@end_date)
               .order(recorded_on: :asc)
  end
end
