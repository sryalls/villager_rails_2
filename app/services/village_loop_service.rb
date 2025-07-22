class VillageLoopService < ApplicationService
  def initialize(village_id)
    @village_id = village_id
  end

  def call
    Rails.logger.info "Processing Village ID: #{@village_id}"

    village = Village.find_by(id: @village_id)
    return failure_result("Village not found") unless village

    buildings_processed = process_village_buildings(village)

    Rails.logger.info "Finished processing Village: #{village.id}"
    success_result("Successfully processed #{buildings_processed} building types", {
      village_id: village.id,
      buildings_processed: buildings_processed
    })
  rescue StandardError => e
    Rails.logger.error "Error processing village #{@village_id}: #{e.message}"
    failure_result("Failed to process village: #{e.message}")
  end

  private

  def process_village_buildings(village)
    building_groups = village.village_buildings
                           .select(&:has_building_outputs?)
                           .group_by(&:building_id)

    building_groups.each do |building_id, village_buildings|
      ProduceResourcesFromBuildingJob.perform_later(building_id, village, village_buildings.count)
    end

    building_groups.count
  end
end
