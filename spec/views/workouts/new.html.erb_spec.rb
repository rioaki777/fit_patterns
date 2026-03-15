require 'rails_helper'

RSpec.describe "workouts/new", type: :view do
  before(:each) do
    assign(:workout, Workout.new(
      kind: "MyString",
      duration_min: 1,
      calories_kcal: 1,
      intensity: 1,
      note: "MyText",
      user: nil
    ))
  end

  it "renders new workout form" do
    render

    assert_select "form[action=?][method=?]", workouts_path, "post" do
      assert_select "input[name=?]", "workout[kind]"

      assert_select "input[name=?]", "workout[duration_min]"

      assert_select "input[name=?]", "workout[calories_kcal]"

      assert_select "input[name=?]", "workout[intensity]"

      assert_select "textarea[name=?]", "workout[note]"

      assert_select "input[name=?]", "workout[user_id]"
    end
  end
end
