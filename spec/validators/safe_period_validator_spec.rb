require "rails_helper"

RSpec.describe SafePeriodValidator do
  subject(:form) do
    WeeklyReportForm.new(
      period_start: period_start,
      period_end: period_end,
      notification_channel: "email"
    )
  end

  context "when period is valid" do
    let(:period_start) { Date.current - 7 }
    let(:period_end)   { Date.current }

    it "is valid" do
      expect(form).to be_valid
    end
  end

  context "when end_date is in the future" do
    let(:period_start) { Date.current - 7 }
    let(:period_end)   { Date.current + 1 }

    it "is invalid" do
      expect(form).not_to be_valid
      expect(form.errors[:period_end]).to be_present
    end
  end

  context "when start_date is after end_date" do
    let(:period_start) { Date.current }
    let(:period_end)   { Date.current - 1 }

    it "is invalid" do
      expect(form).not_to be_valid
      expect(form.errors[:period_start]).to be_present
    end
  end

  context "when period is longer than 31 days" do
    let(:period_start) { Date.current - 40 }
    let(:period_end)   { Date.current }

    it "is invalid" do
      expect(form).not_to be_valid
      expect(form.errors[:base]).to be_present
    end
  end
end
