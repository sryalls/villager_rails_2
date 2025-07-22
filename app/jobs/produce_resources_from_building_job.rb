class ProduceResourcesFromBuildingJob < ApplicationJob
  queue_as :default

  def perform(building_id, village, multiplier = 1, loop_cycle_id: nil)
    Rails.logger.info "Producing resources for Building ID: #{building_id} at #{Time.current} (Cycle: #{loop_cycle_id})"

    result = ProduceResourcesFromBuildingService.call(building_id, village, multiplier, loop_cycle_id: loop_cycle_id)
    handle_service_result(result, context: "Building ID: #{building_id}, Cycle: #{loop_cycle_id}")

    Rails.logger.info "Finished producing resources for Building ID: #{building_id} at #{Time.current}"
  end
end
