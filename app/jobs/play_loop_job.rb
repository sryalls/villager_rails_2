class PlayLoopJob < ApplicationJob
  queue_as :default

  def perform(job_id: nil)
    # Check if a play loop is already running
    unless GameLoopState.can_start_loop?("play_loop")
      Rails.logger.info "Play loop already running, skipping this execution"
      return
    end

    # Start tracking this loop
    loop_state = GameLoopState.start_loop!("play_loop", nil, job_id)

    Rails.logger.info "Play loop started at #{Time.current} (Loop ID: #{loop_state.id})"

    begin
      result = PlayLoopService.call(loop_cycle_id: loop_state.id)
      handle_service_result(result, context: "Play loop, Loop ID: #{loop_state.id}")

      # Mark loop as completed
      loop_state.complete!
      Rails.logger.info "Play loop completed at #{Time.current} (Loop ID: #{loop_state.id})"

    rescue StandardError => e
      # Mark loop as failed
      loop_state.fail!(e.message)
      Rails.logger.error "Play loop failed: #{e.message} (Loop ID: #{loop_state.id})"
      raise
    end
  end
end
