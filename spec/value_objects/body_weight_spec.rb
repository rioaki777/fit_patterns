require "rails_helper"

RSpec.describe BodyWeight do
  let(:weight) { described_class.new(75_000) }

  describe "#grams" do
    it "returns the value in grams" do
      expect(weight.grams).to eq(75_000)
    end
  end

  describe "#to_kg" do
    it "converts grams to kilograms" do
      expect(weight.to_kg).to eq(75.0)
    end
  end

  describe "#formatted" do
    it "returns a formatted string" do
      expect(weight.formatted).to eq("75.0 kg")
    end
  end

  describe "#==" do
    it "is equal to another BodyWeight with same grams" do
      expect(weight).to eq(described_class.new(75_000))
    end

    it "is not equal with different grams" do
      expect(weight).not_to eq(described_class.new(70_000))
    end
  end
end
