require "rails_helper"

RSpec.describe GenerateWeeklyReportWorkflow do
  include FactoryBot::Syntax::Methods

  let(:user) { create(:user) }
  let(:form) do
    WeeklyReportForm.new(
      period_start: 7.days.ago.to_date,
      period_end: Date.current,
      notification_channel: "email"
    )
  end

  it "creates a WeeklyReport" do
    expect {
      described_class.call(user:, form:)
    }.to change(WeeklyReport, :count).by(1)
  end

  it "enqueues a SendWeeklyReportJob" do
    expect {
      described_class.call(user:, form:)
    }.to have_enqueued_job(SendWeeklyReportJob)
  end

  it "returns the created report" do
    report = described_class.call(user:, form:)
    expect(report).to be_a(WeeklyReport)
    expect(report.user).to eq(user)
  end
end
