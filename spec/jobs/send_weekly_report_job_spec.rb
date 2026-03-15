require "rails_helper"

RSpec.describe SendWeeklyReportJob do
  include FactoryBot::Syntax::Methods

  let(:report) { create(:weekly_report) }

  it "delivers via the adapter and marks notified_at" do
    adapter = instance_double(MailNotificationAdapter)
    allow(NotificationAdapter).to receive(:for).with("email").and_return(adapter)
    allow(adapter).to receive(:deliver)

    described_class.perform_now(report.id, "email")

    expect(adapter).to have_received(:deliver).with(report:)
    expect(report.reload.notified_at).to be_present
  end

  it "raises for unknown channels" do
    expect {
      described_class.perform_now(report.id, "unknown")
    }.to raise_error(ArgumentError, /Unknown channel/)
  end
end
