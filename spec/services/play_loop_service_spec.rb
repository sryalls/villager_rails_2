require 'rails_helper'

RSpec.describe PlayLoopService, type: :service do
  describe "#call" do
    before do
      # Clean up all villages and their dependencies first
      VillageResource.destroy_all
      VillageBuilding.destroy_all
      Village.destroy_all
      JobExecution.destroy_all
      # Mock VillageLoopJob
      allow(VillageLoopJob).to receive(:perform_later)
    end

    context "when villages exist" do
      let!(:village1) { create(:village) }
      let!(:village2) { create(:village) }

      it "enqueues VillageLoopJob for each village and returns success" do
        result = PlayLoopService.call

        expect(result.success).to be true
        expect(result.message).to include("Successfully queued processing for 2 villages")
        expect(result.data[:villages_processed]).to eq(2)
        expect(result.data[:processed_at]).to be_a(Time)

        # Assert that VillageLoopJob is enqueued for each village with job_id
        expect(VillageLoopJob).to have_received(:perform_later).with(village1.id, match(/play-loop-\d+-village-#{village1.id}/)).once
        expect(VillageLoopJob).to have_received(:perform_later).with(village2.id, match(/play-loop-\d+-village-#{village2.id}/)).once
      end

      it "records job execution in database" do
        result = PlayLoopService.call

        expect(result.success).to be true
        execution = JobExecution.find_by(job_type: 'PlayLoopJob')
        expect(execution).to be_present
        expect(execution.status).to eq('completed')
        expect(execution.resource_data['villages_processed']).to eq(2)
      end

      it "is idempotent - does not process twice with same job_id" do
        job_id = "test-play-loop-12345"
        
        # First call
        expect {
          @result1 = PlayLoopService.call(job_id: job_id)
        }.to change { JobExecution.count }.by(1)
        
        expect(@result1.success).to be true
        expect(VillageLoopJob).to have_received(:perform_later).twice

        # Verify job execution was recorded
        execution = JobExecution.find_by(job_id: job_id, job_type: 'PlayLoopJob')
        expect(execution).to be_present
        expect(execution.status).to eq('completed')

        # Reset mock completely - use strict verification
        RSpec::Mocks.teardown
        RSpec::Mocks.setup
        allow(VillageLoopJob).to receive(:perform_later)

        # Second call with same job_id should be skipped
        expect {
          @result2 = PlayLoopService.call(job_id: job_id)
        }.not_to change { JobExecution.count }
        
        expect(@result2.success).to be true
        expect(@result2.message).to include("already executed")
        expect(@result2.data[:skipped]).to be true
        expect(VillageLoopJob).not_to have_received(:perform_later)
      end
    end

    context "when no villages exist" do
      it "returns failure result" do
        result = PlayLoopService.call

        expect(result.success).to be false
        expect(result.message).to eq("No villages found")
      end
    end

    context "when an error occurs during processing" do
      before do
        allow(Village).to receive(:all).and_raise(StandardError.new("Database error"))
      end

      it "returns failure result with error message" do
        result = PlayLoopService.call

        expect(result.success).to be false
        expect(result.message).to include("Failed to process play loop")
      end
    end
  end
end
