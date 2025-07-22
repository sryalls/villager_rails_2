require 'rails_helper'

RSpec.describe ProduceResourcesFromBuildingJob, type: :job do
  let(:village) { create(:village) }
  let(:woodcutter) { create(:building, name: "Woodcutter") }

  before do
    allow(ProduceResourcesFromBuildingService).to receive(:call)
  end

  context "when service returns success" do
    let(:success_result) { ::OpenStruct.new(success: true, message: "Success", data: {}) }

    before do
      allow(ProduceResourcesFromBuildingService).to receive(:call).and_return(success_result)
      ProduceResourcesFromBuildingJob.perform_now(woodcutter.id, village, 2)
    end

    it "calls ProduceResourcesFromBuildingService with the correct parameters" do
      expect(ProduceResourcesFromBuildingService).to have_received(:call).with(woodcutter.id, village, 2)
    end
  end

  context "when service returns failure" do
    let(:failure_result) { ::OpenStruct.new(success: false, message: "Error occurred", data: {}) }

    before do
      allow(ProduceResourcesFromBuildingService).to receive(:call).and_return(failure_result)
    end

    it "raises an error" do
      expect {
        ProduceResourcesFromBuildingJob.perform_now(woodcutter.id, village, 2)
      }.to raise_error(StandardError, "Error occurred")
    end
  end
end
