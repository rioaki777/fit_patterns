require "rails_helper"

RSpec.describe WeeklyReport::Generate do
  include FactoryBot::Syntax::Methods

  let(:user)   { create(:user) }
  let(:period) { Period.new(start_date: Date.new(2026, 2, 1), end_date: Date.new(2026, 2, 28)) }

  before do
    create(:weight_entry, user:, recorded_on: Date.new(2026, 2, 10), weight_g: 70_000, body_fat_bp: 1500)
    create(:weight_entry, user:, recorded_on: Date.new(2026, 2, 20), weight_g: 72_000, body_fat_bp: 1600)
    create(:workout,      user:, recorded_on: Date.new(2026, 2, 15), calories_kcal: 300, duration_min: 45)
    create(:workout,      user:, recorded_on: Date.new(2026, 2, 22), calories_kcal: 500, duration_min: 60)
  end

  it "returns averaged and summed stats" do
    result = described_class.call(user:, period:)

    expect(result[:avg_weight_g]).to eq(71_000)
    expect(result[:avg_body_fat_bp]).to eq(1550)
    expect(result[:total_calories_kcal]).to eq(800)
    expect(result[:total_workout_min]).to eq(105)
  end

  context "when there are no weight entries" do
    let(:period) { Period.new(start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 1, 31)) }

    it "returns nil for weight stats" do
      result = described_class.call(user:, period:)
      expect(result[:avg_weight_g]).to be_nil
      expect(result[:avg_body_fat_bp]).to be_nil
    end
  end
end
