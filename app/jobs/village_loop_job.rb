class VillageLoopJob < ApplicationJob
  queue_as :default

  def perform(village_id, loop_cycle_id: nil, village_loop_state_id: nil, job_id: nil)
    # Look up the pre-created village loop state
    if village_loop_state_id
      village_loop_state = GameLoopState.find_by(id: village_loop_state_id)
      unless village_loop_state
        Rails.logger.error "Village loop state not found for ID: #{village_loop_state_id}"
        return
      end
    else
      # Fallback for backward compatibility - create state in job
      unless GameLoopState.can_start_loop?("village_loop", village_id.to_s)
        Rails.logger.info "Village loop already running for Village ID: #{village_id}, skipping"
        return
      end
      village_loop_state = GameLoopState.start_loop!("village_loop", village_id.to_s, job_id)
    end

    # Verify state is still in running status
    unless village_loop_state.running?
      Rails.logger.info "Village loop state #{village_loop_state.id} is not in running status, skipping execution"
      return
    end

    # Get the main play loop state for progress tracking
    main_loop_state = GameLoopState.find_by(id: loop_cycle_id) if loop_cycle_id
    
    begin
      result = VillageLoopService.call(
        village_id, 
        main_loop_state: main_loop_state, 
        village_loop_state: village_loop_state
      )
      handle_service_result(result, context: "Village loop job for Village ID: #{village_id}")
    rescue StandardError => e
      # Ensure loop state is marked as failed if service doesn't handle it
      village_loop_state.fail!(e.message) if village_loop_state.running?
      raise
    end
  end
end
