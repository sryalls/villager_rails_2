require 'rails_helper'

RSpec.describe VillageLoopJob, type: :job do
  context "when performing the job" do
    let(:village) { create(:village) }
    let(:woodcutter) { create(:building, name: "Woodcutter") }
    let(:farm) { create(:building, name: "Farm") }
    let(:service_instance) { instance_double(VillageLoopService) }

    before do
      create(:village_building, village: village, building: woodcutter)
      create(:village_building, village: village, building: farm)

      allow(VillageLoopService).to receive(:new).and_return(service_instance)
      allow(service_instance).to receive(:call)
    end

    it "calls VillageLoopService with the correct village ID" do
      VillageLoopJob.perform_now(village.id)

      expect(VillageLoopService).to have_received(:new)
      expect(service_instance).to have_received(:call).with(village.id)
    end
  end
end
