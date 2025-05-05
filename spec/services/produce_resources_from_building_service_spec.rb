require 'rails_helper'

RSpec.describe ProduceResourcesFromBuildingService, type: :service do
  describe "#call" do
    let(:village) { create(:village) }
    let(:woodcutter) { create(:building, name: "Woodcutter") }
    let!(:logs) { create(:resource, name: "Logs") }

    before do
      create(:building_output, building: woodcutter, resource: logs, quantity: 5)
    end

    context "when the village resource already exists" do
      let!(:village_resource) { create(:village_resource, village: village, resource: logs, count: 10) }

      it "increments the village resource count" do
        ProduceResourcesFromBuildingService.new(woodcutter.id, village, 2).call
        expect(village_resource.reload.count).to eq(20) # 10 + (5 * 2)
      end
    end

    context "when the village resource does not exist" do
      it "creates a new village resource with the correct count" do
        ProduceResourcesFromBuildingService.new(woodcutter.id, village, 1).call
        village_resource = VillageResource.find_by(village: village, resource: logs)

        expect(village_resource).to have_attributes(count: 5) # 0 + (5 * 1)
      end
    end
  end
end
