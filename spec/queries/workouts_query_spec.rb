require "rails_helper"

RSpec.describe WorkoutsQuery do
  include FactoryBot::Syntax::Methods

  let(:user)   { create(:user) }
  let(:period) { Period.new(start_date: Date.new(2026, 2, 1), end_date: Date.new(2026, 2, 28)) }

  before do
    create(:workout, user:, recorded_on: Date.new(2026, 2, 10))
    create(:workout, user:, recorded_on: Date.new(2026, 2, 20))
    create(:workout, user:, recorded_on: Date.new(2026, 3, 1))  # outside range
    create(:workout, recorded_on: Date.new(2026, 2, 15))        # different user
  end

  it "returns only workouts for the user within the period" do
    result = described_class.call(user:, period:)
    expect(result.count).to eq(2)
  end

  it "orders by recorded_on ascending" do
    result = described_class.call(user:, period:)
    expect(result.map(&:recorded_on)).to eq([Date.new(2026, 2, 10), Date.new(2026, 2, 20)])
  end
end
