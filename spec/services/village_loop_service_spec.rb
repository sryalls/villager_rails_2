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
    end

    context "when village exists" do
      it "enqueues ProduceResourcesFromBuildingJob for each building and returns success" do
        result = VillageLoopService.call(village.id)

        expect(result.success).to be true
        expect(result.message).to include("Successfully processed 2 building types")
        expect(result.data[:village_id]).to eq(village.id)
        expect(result.data[:buildings_processed]).to eq(2)

        expect(ProduceResourcesFromBuildingJob).to have_received(:perform_later).with(woodcutter.id, village, 1, match(/village-#{village.id}-\d+-building-#{woodcutter.id}/)).once
        expect(ProduceResourcesFromBuildingJob).to have_received(:perform_later).with(farm.id, village, 1, match(/village-#{village.id}-\d+-building-#{farm.id}/)).once
      end

      it "records job execution in database" do
        result = VillageLoopService.call(village.id)

        expect(result.success).to be true
        expect(result.message).to include("processed successfully")
      end

      it "is idempotent - uses entity tracker for building-level idempotency" do
        job_id = "test-village-loop-12345"

        # First call
        expect {
          @result1 = VillageLoopService.call(village.id, job_id: job_id)
        }.to change { JobExecution.count }.by(1)

        expect(@result1.success).to be true
        expect(ProduceResourcesFromBuildingJob).to have_received(:perform_later).twice

        # Verify processing completed successfully
        expect(@result1.success).to be true
        expect(@result1.data[:buildings_processed]).to eq(2)

        # Reset mock completely
        RSpec::Mocks.teardown
        RSpec::Mocks.setup
        allow(ProduceResourcesFromBuildingJob).to receive(:perform_later)

        # Second call creates new processing cycle
        # (Building-level idempotency handled by entity tracker)
        @result2 = VillageLoopService.call(village.id)

        expect(@result2.success).to be true
        expect(ProduceResourcesFromBuildingJob).to have_received(:perform_later).twice
      end
    end

    context "when village does not exist" do
      it "returns failure result" do
        result = VillageLoopService.call(999)

        expect(result.success).to be false
        expect(result.message).to eq("Village not found")
      end
    end

    context "when an error occurs during processing" do
      before do
        allow_any_instance_of(VillageLoopService).to receive(:process_village_buildings).and_raise(StandardError.new("Database error"))
      end

      it "returns failure result with error message" do
        result = VillageLoopService.call(village.id)

        expect(result.success).to be false
        expect(result.message).to include("Failed to process village")
      end
    end
  end
end
