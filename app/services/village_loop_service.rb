class VillageLoopService < ApplicationService
  def initialize(village_id, loop_cycle_id: nil, village_loop_state_id: nil, loop_state: nil)
    @village_id = village_id
    @loop_cycle_id = loop_cycle_id
    @village_loop_state_id = village_loop_state_id
    @loop_state = loop_state
    
    # For backward compatibility, if only loop_cycle_id is provided, find the state
    if @loop_cycle_id && !@loop_state
      @loop_state = GameLoopState.find_by(id: @loop_cycle_id)
    end
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
    return 0 unless @loop_state
    
    building_groups = village.village_buildings
                           .select(&:has_building_outputs?)
                           .group_by(&:building_id)

    # Get buildings that have already been processed in this loop (for retry scenarios)
    already_processed_buildings = @loop_state.processed_buildings_for_village(village)

    building_groups.each do |building_id, village_buildings|
      building = Building.find(building_id)

      # Skip if already processed in this loop
      unless @loop_state.building_processed?(village, building)
        ProduceResourcesFromBuildingJob.perform_later(
          building_id,
          village,
          village_buildings.count,
          loop_cycle_id: @loop_cycle_id
        )
        @loop_state.mark_building_processed!(village, building)
      else
        Rails.logger.info "Skipping Building #{building_id} - already processed in this loop"
      end
    end

    building_groups.count
  end
end
