class VillageLoopService < ApplicationService
  def initialize(village_id, loop_cycle_id: nil, job_id: nil)
    @village_id = village_id
    @loop_cycle_id = loop_cycle_id
    @job_id = job_id
    @main_loop_state = nil
    @village_loop_state = nil
  end

  def call
    # Check if a village loop is already running for this village
    unless GameLoopState.can_start_loop?("village_loop", @village_id.to_s)
      Rails.logger.info "Village loop already running for Village ID: #{@village_id}, skipping"
      return success_result("Village loop already running, execution skipped", { skipped: true })
    end

    # Start tracking this village loop
    @village_loop_state = GameLoopState.start_loop!("village_loop", @village_id.to_s, @job_id)

    # Get the main play loop state for progress tracking
    @main_loop_state = GameLoopState.find_by(id: @loop_cycle_id) if @loop_cycle_id

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
        loop_cycle_id: @loop_cycle_id,
        village_loop_state_id: @village_loop_state.id
      })
    rescue StandardError => e
      # Mark village loop as failed
      @village_loop_state&.fail!(e.message)
      Rails.logger.error "Village loop failed for Village ID: #{@village_id}: #{e.message} (Loop ID: #{@village_loop_state&.id})"
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
          loop_cycle_id: @loop_cycle_id
        )
        @main_loop_state.mark_building_processed!(village, building)
      else
        Rails.logger.info "Skipping Building #{building_id} - already processed in this loop"
      end
    end

    building_groups.count
  end
end
