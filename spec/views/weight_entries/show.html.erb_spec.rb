require 'rails_helper'

RSpec.describe "weight_entries/show", type: :view do
  before(:each) do
    assign(:weight_entry, create(:weight_entry))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/70000/)
  end
end
