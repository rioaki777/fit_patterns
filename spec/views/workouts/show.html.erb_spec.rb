require 'rails_helper'

RSpec.describe "workouts/show", type: :view do
  before(:each) do
    assign(:workout, create(:workout))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/running/)
  end
end
