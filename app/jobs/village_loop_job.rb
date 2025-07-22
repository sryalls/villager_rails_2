class VillageLoopJob < ApplicationJob
  queue_as :default

  def perform(village_id, job_id = nil)
    job_id ||= "village-#{village_id}-#{Time.current.to_i}"
    
    Rails.logger.info "VillageJob started for Village ID: #{village_id} at #{Time.current} (Job ID: #{job_id})"

    result = VillageLoopService.call(village_id, job_id: job_id)
    handle_service_result(result, context: "Village ID: #{village_id}, Job ID: #{job_id}")

    Rails.logger.info "VillageJob completed for Village ID: #{village_id} at #{Time.current}"
  end
end
