require "rails_helper"

RSpec.describe GenerateWeeklyReportCommand do
  include FactoryBot::Syntax::Methods

  let(:user) { create(:user) }

  describe ".call" do
    context "when form is valid" do
      let(:form) do
        WeeklyReportForm.new(
          period_start: 7.days.ago.to_date,
          period_end: Date.current,
          notification_channel: "email"
        )
      end

      it "returns a successful result with a report" do
        result = described_class.call(user:, form:)
        expect(result.success?).to be true
        expect(result.report).to be_a(WeeklyReport)
      end
    end

    context "when form is invalid" do
      let(:form) do
        WeeklyReportForm.new(
          period_start: nil,
          period_end: nil,
          notification_channel: "email"
        )
      end

      it "returns a failed result with errors" do
        result = described_class.call(user:, form:)
        expect(result.success?).to be false
        expect(result.errors).to be_present
      end
    end
  end
end
