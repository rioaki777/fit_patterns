require "rails_helper"

RSpec.describe Period do
  let(:start_date) { Date.new(2026, 2, 23) }
  let(:end_date)   { Date.new(2026, 3, 1) }
  let(:period)     { described_class.new(start_date:, end_date:) }

  describe "#days" do
    it "returns the number of days inclusive" do
      expect(period.days).to eq(7)
    end
  end

  describe "#covers?" do
    it "returns true for a date within the range" do
      expect(period.covers?(Date.new(2026, 2, 25))).to be true
    end

    it "returns false for a date outside the range" do
      expect(period.covers?(Date.new(2026, 3, 5))).to be false
    end
  end

  describe "#to_range" do
    it "returns a Range of dates" do
      expect(period.to_range).to eq(start_date..end_date)
    end
  end

  describe "#==" do
    it "is equal to another Period with same dates" do
      other = described_class.new(start_date:, end_date:)
      expect(period).to eq(other)
    end

    it "is not equal to a Period with different dates" do
      other = described_class.new(start_date: start_date + 1, end_date:)
      expect(period).not_to eq(other)
    end
  end

  describe ".current_week" do
    it "returns a Period for the current week" do
      result = described_class.current_week
      expect(result.start_date).to eq(Date.current.beginning_of_week)
      expect(result.end_date).to eq(Date.current.end_of_week)
    end
  end

  it "is frozen" do
    expect(period).to be_frozen
  end
end
