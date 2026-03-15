require 'rails_helper'

RSpec.describe "weight_entries/new", type: :view do
  before(:each) do
    assign(:weight_entry, WeightEntry.new(
      weight_g: 1,
      body_fat_bp: 1,
      note: "MyText",
      user: nil
    ))
  end

  it "renders new weight_entry form" do
    render

    assert_select "form[action=?][method=?]", weight_entries_path, "post" do

      assert_select "input[name=?]", "weight_entry[weight_g]"

      assert_select "input[name=?]", "weight_entry[body_fat_bp]"

      assert_select "textarea[name=?]", "weight_entry[note]"

      assert_select "input[name=?]", "weight_entry[user_id]"
    end
  end
end
