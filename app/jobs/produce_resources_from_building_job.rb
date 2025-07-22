class ProduceResourcesFromBuildingJob < ApplicationJob
  queue_as :default

  def perform(building_id, village, multiplier = 1)
    Rails.logger.info "Producing resources for Building ID: #{building_id} at #{Time.current}"

    result = ProduceResourcesFromBuildingService.call(building_id, village, multiplier)
    handle_service_result(result, context: "Building ID: #{building_id}")

    Rails.logger.info "Finished producing resources for Building ID: #{building_id} at #{Time.current}"
  end
end
