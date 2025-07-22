require 'rails_helper'

RSpec.describe PlayLoopJob, type: :job do
  let(:village) { create(:village) }
  let(:woodcutter) { create(:building, name: "Woodcutter") }
  let(:farm) { create(:building, name: "Farm") }
  let(:wood) { create(:resource, name: "Wood") }
  let(:food) { create(:resource, name: "Food") }

  before do
    create(:building_output, building: woodcutter, resource: wood, quantity: 1)
    create(:building_output, building: farm, resource: food, quantity: 1)
    create(:village_building, village: village, building: woodcutter)
    create(:village_building, village: village, building: farm)

    allow(VillageLoopJob).to receive(:perform_later).and_wrap_original do |method, *args, **kwargs|
      VillageLoopJob.perform_now(*args, **kwargs)
    end
    allow(ProduceResourcesFromBuildingJob).to receive(:perform_later).and_wrap_original do |method, *args, **kwargs|
      ProduceResourcesFromBuildingJob.perform_now(*args, **kwargs)
    end
  end

  context "when PlayLoopJob is performed" do
    before { PlayLoopJob.perform_now }

    it "adds the correct amount of wood to the village resources" do
      expect(village.village_resources.find_by(resource: wood).count).to eq(1)
    end

    it "adds the correct amount of food to the village resources" do
      expect(village.village_resources.find_by(resource: food).count).to eq(1)
    end
  end

  context "when a building output has a quantity greater than 1" do
    before do
      woodcutter.building_outputs.find_by(resource: wood).update(quantity: 3)
      PlayLoopJob.perform_now
    end

    it "adds the correct amount of wood to the village resources" do
      expect(village.village_resources.find_by(resource: wood).count).to eq(3)
    end
  end

  context "when there are multiple farms attached to the village" do
    before do
      create(:village_building, village: village, building: farm)
      PlayLoopJob.perform_now
    end

    it "adds the correct amount of food to the village resources" do
      expect(village.village_resources.find_by(resource: food).count).to eq(2)
    end
  end
end
