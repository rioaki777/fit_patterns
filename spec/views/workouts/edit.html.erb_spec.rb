require 'rails_helper'

RSpec.describe "workouts/edit", type: :view do
  let(:workout) { create(:workout) }

  before(:each) do
    assign(:workout, workout)
  end

  it "renders the edit workout form" do
    render

    assert_select "form[action=?][method=?]", workout_path(workout), "post" do
      assert_select "input[name=?]", "workout[kind]"
      assert_select "input[name=?]", "workout[duration_min]"
      assert_select "input[name=?]", "workout[calories_kcal]"
      assert_select "input[name=?]", "workout[intensity]"
      assert_select "textarea[name=?]", "workout[note]"
    end
  end
end
