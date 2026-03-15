require 'rails_helper'

RSpec.describe "weight_entries/edit", type: :view do
  let(:weight_entry) { create(:weight_entry) }

  before(:each) do
    assign(:weight_entry, weight_entry)
  end

  it "renders the edit weight_entry form" do
    render

    assert_select "form[action=?][method=?]", weight_entry_path(weight_entry), "post" do
      assert_select "input[name=?]", "weight_entry[weight_g]"
      assert_select "input[name=?]", "weight_entry[body_fat_bp]"
      assert_select "textarea[name=?]", "weight_entry[note]"
    end
  end
end
