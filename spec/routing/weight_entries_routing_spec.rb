require "rails_helper"

RSpec.describe WeightEntriesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/weight_entries").to route_to("weight_entries#index")
    end

    it "routes to #new" do
      expect(get: "/weight_entries/new").to route_to("weight_entries#new")
    end

    it "routes to #show" do
      expect(get: "/weight_entries/1").to route_to("weight_entries#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/weight_entries/1/edit").to route_to("weight_entries#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/weight_entries").to route_to("weight_entries#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/weight_entries/1").to route_to("weight_entries#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/weight_entries/1").to route_to("weight_entries#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/weight_entries/1").to route_to("weight_entries#destroy", id: "1")
    end
  end
end
