class PlayLoopJob < ApplicationJob
  queue_as :default

  def perform(loop_state_id: nil, job_id: nil)
    # Look up the pre-created loop state
    if loop_state_id
      loop_state = GameLoopState.find_by(id: loop_state_id)
      unless loop_state
        Rails.logger.error "Loop state not found for ID: #{loop_state_id}"
        return
      end
    else
      # Fallback for backward compatibility - create state in job
      unless GameLoopState.can_start_loop?("play_loop")
        Rails.logger.info "Play loop already running, skipping this execution"
        return
      end
      loop_state = GameLoopState.start_loop!("play_loop", nil, job_id)
    end
    
    # Verify state is still in running status
    unless loop_state.running?
      Rails.logger.info "Loop state #{loop_state.id} is not in running status, skipping execution"
      return
    end
    
    begin
      result = PlayLoopService.call(loop_state: loop_state)
      handle_service_result(result, context: "Play loop job")
    rescue StandardError => e
      # Ensure loop state is marked as failed if service doesn't handle it
      loop_state.fail!(e.message) if loop_state.running?
      raise
    end
  end
end
