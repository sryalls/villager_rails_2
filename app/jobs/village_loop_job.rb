class VillageLoopJob < ApplicationJob
  queue_as :default

  def perform(village_id)
    Rails.logger.info "VillageJob started for Village ID: #{village_id} at #{Time.current}"
    VillageLoopService.new.call(village_id)
    Rails.logger.info "VillageJob completed for Village ID: #{village_id} at #{Time.current}"
  end
end
