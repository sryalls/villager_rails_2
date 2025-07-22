require 'rails_helper'

RSpec.describe VillageLoopJob, type: :job do
  context "when performing the job" do
    let(:village) { create(:village) }
    let(:woodcutter) { create(:building, name: "Woodcutter") }
    let(:farm) { create(:building, name: "Farm") }

    before do
      create(:village_building, village: village, building: woodcutter)
      create(:village_building, village: village, building: farm)

      allow(VillageLoopService).to receive(:call)
    end

    context "when service returns success" do
      let(:success_result) { ::OpenStruct.new(success: true, message: "Success", data: {}) }

      before do
        allow(VillageLoopService).to receive(:call).and_return(success_result)
      end

      it "calls VillageLoopService with the correct village ID" do
        VillageLoopJob.perform_now(village.id)

        expect(VillageLoopService).to have_received(:call).with(village.id)
      end
    end

    context "when service returns failure" do
      let(:failure_result) { ::OpenStruct.new(success: false, message: "Error occurred", data: {}) }

      before do
        allow(VillageLoopService).to receive(:call).and_return(failure_result)
      end

      it "raises an error" do
        expect {
          VillageLoopJob.perform_now(village.id)
        }.to raise_error(StandardError, "Error occurred")
      end
    end
  end
end
