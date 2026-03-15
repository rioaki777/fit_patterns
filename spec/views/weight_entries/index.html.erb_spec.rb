require 'rails_helper'

RSpec.describe "weight_entries/index", type: :view do
  let(:user) { create(:user) }

  before(:each) do
    assign(:weight_entries, create_list(:weight_entry, 2, user: user))
  end

  it "renders a list of weight_entries" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(70_000.to_s), count: 2
  end
end
