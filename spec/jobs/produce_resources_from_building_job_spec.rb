require 'rails_helper'

RSpec.describe ProduceResourcesFromBuildingJob, type: :job do
  let(:village) { create(:village) }
  let(:woodcutter) { create(:building, name: "Woodcutter") }
  let(:service_instance) { instance_double(ProduceResourcesFromBuildingService) }

  before do
      allow(ProduceResourcesFromBuildingService).to receive(:new).and_return(service_instance)
      allow(service_instance).to receive(:call)

      ProduceResourcesFromBuildingJob.perform_now(woodcutter.id, village, 2)
  end
  it "calls ProduceResourcesFromBuildingService with the correct parameters" do
    expect(ProduceResourcesFromBuildingService).to have_received(:new).with(woodcutter.id, village, 2)
    expect(service_instance).to have_received(:call).once
  end
end
