class VillageLoopService < ApplicationService
  def initialize(village_id, main_loop_state:, village_loop_state:)
    @village_id = village_id
    @main_loop_state = main_loop_state
    @village_loop_state = village_loop_state
  end

  def call
    Rails.logger.info "Village loop started for Village ID: #{@village_id} at #{Time.current} (Loop ID: #{@village_loop_state.id})"

    begin
      village = Village.find_by(id: @village_id)
      return failure_result("Village not found") unless village

      buildings_processed = process_village_buildings(village)

      # Mark village loop as completed
      @village_loop_state.complete!
      Rails.logger.info "Village loop completed for Village ID: #{@village_id} at #{Time.current} (Loop ID: #{@village_loop_state.id})"

      success_result("Successfully processed #{buildings_processed} building types", {
        village_id: village.id,
        buildings_processed: buildings_processed,
        main_loop_state_id: @main_loop_state&.id,
        village_loop_state_id: @village_loop_state.id
      })
    rescue StandardError => e
      # Mark village loop as failed
      @village_loop_state.fail!(e.message)
      Rails.logger.error "Village loop failed for Village ID: #{@village_id}: #{e.message} (Loop ID: #{@village_loop_state.id})"
      failure_result("Failed to process village: #{e.message}")
    end
  end

  private

  def process_village_buildings(village)
    return 0 unless @main_loop_state

    building_groups = village.village_buildings
                           .select(&:has_building_outputs?)
                           .group_by(&:building_id)

    # Get buildings that have already been processed in this loop (for retry scenarios)
    already_processed_buildings = @main_loop_state.processed_buildings_for_village(village)

    building_groups.each do |building_id, village_buildings|
      building = Building.find(building_id)

      # Skip if already processed in this loop
      unless @main_loop_state.building_processed?(village, building)
        ProduceResourcesFromBuildingJob.perform_later(
          building_id,
          village,
          village_buildings.count,
          loop_cycle_id: @main_loop_state&.id
        )
        @main_loop_state.mark_building_processed!(village, building)
      else
        Rails.logger.info "Skipping Building #{building_id} - already processed in this loop"
      end
    end

    building_groups.count
  end
end
