require 'rails_helper'

RSpec.describe "VillageBuildings", type: :request do
  let!(:user) { create(:user) }
  let!(:village) { create(:village, user: user) }
  let!(:building) { create(:building) }
  let!(:resource) { create(:resource) }
  let!(:village_resource) { create(:village_resource, village: village, resource: resource, count: 100) }

  before do
    sign_in user
  end

  describe "POST /villages/:village_id/village_buildings" do
    context "with sufficient resources" do
      it "creates a new building and deducts resources" do
        post village_village_buildings_path(village), params: {
          village_building: {
            building_id: building.id,
            resources: { resource.id.to_s => 50 }
          }
        }

        expect(response).to redirect_to(village_path(village))
        follow_redirect!

        expect(response.body).to include("Building was successfully added.")
        expect(village.buildings).to include(building)
        expect(village.village_resources.find_by(resource_id: resource.id).count).to eq(50)
      end
    end

    context "with insufficient resources" do
      it "does not create a new building and shows an alert" do
        post village_village_buildings_path(village), params: {
          village_building: {
            building_id: building.id,
            resources: { resource.id.to_s => 150 }
          }
        }

        expect(response).to redirect_to(village_path(village))
        follow_redirect!

        expect(response.body).to include("Insufficient resources to build this building.")
        expect(village.buildings).not_to include(building)
        expect(village.village_resources.find_by(resource_id: resource.id).count).to eq(100)
      end
    end
  end
end
