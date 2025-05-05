require 'rails_helper'

RSpec.describe PlayLoopService, type: :service do
  describe "#call" do
    let!(:village1) { create(:village) }
    let!(:village2) { create(:village) }

    it "enqueues VillageLoopJob for each village" do
      # Mock VillageLoopJob
      allow(VillageLoopJob).to receive(:perform_later)

      # Call the service
      PlayLoopService.new.call

      # Assert that VillageLoopJob is enqueued for each village
      expect(VillageLoopJob).to have_received(:perform_later).with(village1.id).once
      expect(VillageLoopJob).to have_received(:perform_later).with(village2.id).once
    end
  end
end
