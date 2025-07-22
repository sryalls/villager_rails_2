class VillageLoopJob < ApplicationJob
  queue_as :default

  def perform(village_id, loop_cycle_id: nil)
    # Check if a village loop is already running for this village
    unless GameLoopState.can_start_loop?("village_loop", village_id.to_s)
      Rails.logger.info "Village loop already running for Village ID: #{village_id}, skipping"
      return
    end

    # Start tracking this loop
    loop_state = GameLoopState.start_loop!("village_loop", village_id.to_s, job_id)

    Rails.logger.info "Village loop started for Village ID: #{village_id} at #{Time.current} (Loop ID: #{loop_state.id})"

    begin
      # Get the main play loop state for progress tracking
      main_loop_state = GameLoopState.find_by(id: loop_cycle_id) if loop_cycle_id
      
      result = VillageLoopService.call(
        village_id, 
        loop_cycle_id: loop_cycle_id, 
        village_loop_state_id: loop_state.id,
        loop_state: main_loop_state
      )
      handle_service_result(result, context: "Village ID: #{village_id}, Loop ID: #{loop_state.id}")

      # Mark loop as completed
      loop_state.complete!
      Rails.logger.info "Village loop completed for Village ID: #{village_id} at #{Time.current} (Loop ID: #{loop_state.id})"

    rescue StandardError => e
      # Mark loop as failed
      loop_state.fail!(e.message)
      Rails.logger.error "Village loop failed for Village ID: #{village_id}: #{e.message} (Loop ID: #{loop_state.id})"
      raise
    end
  end
end
