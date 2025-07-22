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

      it "records job execution in database" do
        result = ProduceResourcesFromBuildingService.call(woodcutter.id, village, 1)

        expect(result.success).to be true
        execution = JobExecution.find_by(job_type: 'ProduceResourcesFromBuildingJob')
        expect(execution).to be_present
        expect(execution.status).to eq('completed')
        expect(execution.building_id).to eq(woodcutter.id)
        expect(execution.village_id).to eq(village.id)
      end

      it "is idempotent - does not process twice with same job_id" do
        job_id = "test-produce-12345"
        
        # First call
        expect {
          @result1 = ProduceResourcesFromBuildingService.call(woodcutter.id, village, 1, job_id: job_id)
        }.to change { JobExecution.count }.by(1)
        
        expect(@result1.success).to be true
        village_resource = VillageResource.find_by(village: village, resource: logs)
        expect(village_resource.count).to eq(5)

        # Verify job execution was recorded
        execution = JobExecution.find_by(job_id: job_id, job_type: 'ProduceResourcesFromBuildingJob')
        expect(execution).to be_present
        expect(execution.status).to eq('completed')

        # Second call with same job_id should be skipped
        expect {
          @result2 = ProduceResourcesFromBuildingService.call(woodcutter.id, village, 1, job_id: job_id)
        }.not_to change { JobExecution.count }
        
        expect(@result2.success).to be true
        expect(@result2.message).to include("already executed")
        expect(@result2.data[:skipped]).to be true
        
        # Resource count should not change
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
