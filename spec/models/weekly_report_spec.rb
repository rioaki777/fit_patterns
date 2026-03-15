require "rails_helper"

RSpec.describe WeeklyReport, type: :model do
  include FactoryBot::Syntax::Methods

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:audit_logs) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:period_start) }
    it { is_expected.to validate_presence_of(:period_end) }
  end

  describe "value object accessors" do
    let(:report) { build(:weekly_report, avg_weight_g: 70_000, avg_body_fat_bp: 1500, total_calories_kcal: 500) }

    it "returns BodyWeight for avg_weight" do
      expect(report.avg_weight).to eq(BodyWeight.new(70_000))
    end

    it "returns BodyFatRate for avg_body_fat" do
      expect(report.avg_body_fat).to eq(BodyFatRate.new(1500))
    end

    it "returns Calories for total_cal" do
      expect(report.total_cal).to eq(Calories.new(500))
    end

    it "returns nil when avg_weight_g is nil" do
      report.avg_weight_g = nil
      expect(report.avg_weight).to be_nil
    end
  end

  describe "Trackable concern" do
    it "responds to recently_modified scope" do
      expect(described_class).to respond_to(:recently_modified)
    end

    it "responds to age_in_days" do
      report = build(:weekly_report)
      expect(report).to respond_to(:age_in_days)
    end
  end

  describe "after_commit callback" do
    it "creates an audit_log on create" do
      expect {
        create(:weekly_report)
      }.to change(AuditLog, :count).by(1)
    end
  end
end
