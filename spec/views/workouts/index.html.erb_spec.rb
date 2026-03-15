require 'rails_helper'

RSpec.describe "workouts/index", type: :view do
  let(:user) { create(:user) }

  before(:each) do
    assign(:workouts, create_list(:workout, 2, user: user))
  end

  it "renders a list of workouts" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("running"), count: 2
  end
end
