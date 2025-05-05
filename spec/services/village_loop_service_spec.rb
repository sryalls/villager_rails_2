require 'rails_helper'

RSpec.describe VillageLoopService, type: :service do
  describe "#call" do
    let(:village) { create(:village) }
    let(:woodcutter) { create(:building, name: "Woodcutter") }
    let(:farm) { create(:building, name: "Farm") }

    before do
      # Create village buildings with outputs
      create(:village_building, village: village, building: woodcutter)
      create(:village_building, village: village, building: farm)

      # Mock the `has_building_outputs?` method
      allow_any_instance_of(VillageBuilding).to receive(:has_building_outputs?).and_return(true)

      # Mock ProduceResourcesFromBuildingJob
      allow(ProduceResourcesFromBuildingJob).to receive(:perform_later)

      VillageLoopService.new.call(village.id)
    end

    it "enqueues ProduceResourcesFromBuildingJob for each building with the correct parameters" do
      expect(ProduceResourcesFromBuildingJob).to have_received(:perform_later).with(woodcutter.id, village, 1).once
      expect(ProduceResourcesFromBuildingJob).to have_received(:perform_later).with(farm.id, village, 1).once
    end
  end
end
