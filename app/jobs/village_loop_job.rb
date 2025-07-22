class VillageLoopJob < ApplicationJob
  queue_as :default

  def perform(village_id)
    Rails.logger.info "VillageJob started for Village ID: #{village_id} at #{Time.current}"

    result = VillageLoopService.call(village_id)
    handle_service_result(result, context: "Village ID: #{village_id}")

    Rails.logger.info "VillageJob completed for Village ID: #{village_id} at #{Time.current}"
  end
end
