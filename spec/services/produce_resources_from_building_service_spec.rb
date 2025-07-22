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

      it "increments the village resource count and returns success" do
        result = ProduceResourcesFromBuildingService.call(woodcutter.id, village, 2)

        expect(result.success).to be true
        expect(result.message).to include("Successfully produced resources from Woodcutter")
        expect(result.data[:building_name]).to eq("Woodcutter")
        expect(result.data[:multiplier]).to eq(2)
        expect(result.data[:total_quantity]).to eq(10) # 5 * 2
        expect(village_resource.reload.count).to eq(20) # 10 + (5 * 2)
      end
    end

    context "when the village resource does not exist" do
      it "creates a new village resource with the correct count and returns success" do
        result = ProduceResourcesFromBuildingService.call(woodcutter.id, village, 1)
        village_resource = VillageResource.find_by(village: village, resource: logs)

        expect(result.success).to be true
        expect(result.message).to include("Successfully produced resources from Woodcutter")
        expect(result.data[:building_name]).to eq("Woodcutter")
        expect(result.data[:multiplier]).to eq(1)
        expect(result.data[:total_quantity]).to eq(5) # 5 * 1
        expect(village_resource).to have_attributes(count: 5) # 0 + (5 * 1)
      end

      it "processes resource production successfully" do
        result = ProduceResourcesFromBuildingService.call(woodcutter.id, village, 1)

        expect(result.success).to be true
        expect(result.message).to include("Successfully produced resources")
        expect(result.data[:resources_produced]).to be_present
      end

      it "is idempotent - does not process twice with same job_id" do
        job_id = "test-produce-12345"

        # First call
        expect {
          @result1 = ProduceResourcesFromBuildingService.call(woodcutter.id, village, 1, job_id: job_id)
        expect(@result1.success).to be true
        village_resource = VillageResource.find_by(village: village, resource: logs)
        expect(village_resource.count).to eq(5)

        # Create entity tracker for idempotency testing
        tracker = GameLoopEntityTracker.new(job_id)
        expect(tracker.resource_produced?(logs.id, woodcutter.id, village.id)).to be_truthy

        # Second call with same cycle should be skipped at resource level
        @result2 = ProduceResourcesFromBuildingService.call(
          woodcutter.id, village, 1, loop_cycle_id: job_id
        )

        expect(@result2.success).to be true
        
        # Resource count should not change due to entity tracker idempotency
        expect(village_resource.reload.count).to eq(5)
      end
    end

    context "when building does not exist" do
      it "returns failure result" do
        result = ProduceResourcesFromBuildingService.call(999, village, 1)

        expect(result.success).to be false
        expect(result.message).to eq("Building not found")
      end
    end

    context "when an error occurs during processing" do
      before do
        allow(VillageResource).to receive(:find_or_create_by!).and_raise(StandardError.new("Database error"))
      end

      it "returns failure result with error message" do
        result = ProduceResourcesFromBuildingService.call(woodcutter.id, village, 1)

        expect(result.success).to be false
        expect(result.message).to include("Failed to process building outputs")
      end
    end
  end
end
