require "rails_helper"

RSpec.describe WeeklyReportPolicy do
  include FactoryBot::Syntax::Methods

  let(:user)   { create(:user) }
  let(:report) { build(:weekly_report, user:) }

  describe "#create?" do
    it "returns true when user is present" do
      policy = described_class.new(user, nil)
      expect(policy.create?).to be true
    end

    it "returns false when user is nil" do
      policy = described_class.new(nil, nil)
      expect(policy.create?).to be false
    end
  end

  describe "#show?" do
    it "returns true when report belongs to user" do
      policy = described_class.new(user, report)
      expect(policy.show?).to be true
    end

    it "returns false when report belongs to another user" do
      other_user = create(:user)
      policy = described_class.new(other_user, report)
      expect(policy.show?).to be false
    end
  end
end
