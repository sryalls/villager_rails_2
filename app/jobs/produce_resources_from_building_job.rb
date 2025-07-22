class ProduceResourcesFromBuildingJob < ApplicationJob
  queue_as :default

  def perform(building_id, village, multiplier = 1, job_id = nil)
    job_id ||= "building-#{building_id}-#{village.id}-#{multiplier}-#{Time.current.to_i}"

    Rails.logger.info "Producing resources for Building ID: #{building_id} at #{Time.current} (Job ID: #{job_id})"

    result = ProduceResourcesFromBuildingService.call(building_id, village, multiplier, job_id: job_id)
    handle_service_result(result, context: "Building ID: #{building_id}, Job ID: #{job_id}")

    Rails.logger.info "Finished producing resources for Building ID: #{building_id} at #{Time.current}"
  end
end
