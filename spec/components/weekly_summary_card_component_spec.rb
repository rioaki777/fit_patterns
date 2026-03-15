require "rails_helper"

RSpec.describe WeeklySummaryCardComponent, type: :component do
  include FactoryBot::Syntax::Methods

  let(:report) do
    build(:weekly_report,
      period_start: Date.new(2026, 2, 23),
      period_end: Date.new(2026, 3, 1),
      avg_weight_g: 70_000,
      avg_body_fat_bp: 1550,
      total_calories_kcal: 2100,
      notified_at: nil
    )
  end
  let(:presenter) { WeeklyReportPresenter.new(report) }

  it "renders the period" do
    render_inline(described_class.new(presenter:))
    expect(page).to have_text("2026-02-23 〜 2026-03-01")
  end

  it "renders formatted weight" do
    render_inline(described_class.new(presenter:))
    expect(page).to have_text("70.0 kg")
  end

  it "renders notification status as 未送信" do
    render_inline(described_class.new(presenter:))
    expect(page).to have_text("未送信")
  end
end
