class VillageLoopService < ApplicationService
  def initialize(village_id, loop_cycle_id: nil, village_loop_state_id: nil)
    @village_id = village_id
    @loop_cycle_id = loop_cycle_id
    @village_loop_state_id = village_loop_state_id
  end

  def call
    Rails.logger.info "Processing Village ID: #{@village_id} (Cycle: #{@loop_cycle_id})"

    village = Village.find_by(id: @village_id)
    return failure_result("Village not found") unless village

    buildings_processed = process_village_buildings(village)

    Rails.logger.info "Finished processing Village: #{village.id}"
    success_result("Successfully processed #{buildings_processed} building types", {
      village_id: village.id,
      buildings_processed: buildings_processed,
      loop_cycle_id: @loop_cycle_id
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

    # Get buildings that have already been processed in this cycle (for retry scenarios)
    already_processed_buildings = GameLoopProgress.processed_buildings_for_village_cycle(@loop_cycle_id, village)
    
    building_groups.each do |building_id, village_buildings|
      building = Building.find(building_id)
      
      # Skip if already processed in this cycle
      unless already_processed_buildings.include?(building)
        ProduceResourcesFromBuildingJob.perform_later(
          building_id,
          village,
          village_buildings.count,
          loop_cycle_id: @loop_cycle_id
        )
        GameLoopProgress.mark_building_processed!(@loop_cycle_id, village, building)
      else
        Rails.logger.info "Skipping Building #{building_id} - already processed in this cycle"
      end
    end

    building_groups.count
  end
end
