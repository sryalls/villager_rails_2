class GameLoopManager
  # Queue a play loop job with proper state management
  # Creates the GameLoopState before enqueueing the job for maximum robustness
  def self.queue_play_loop!(job_id: nil)
    unless GameLoopState.can_start_loop?("play_loop")
      Rails.logger.info "Play loop already running, not queuing new job"
      return false
    end

    # Create state atomically before enqueueing
    loop_state = GameLoopState.start_loop!("play_loop", nil, job_id)
    PlayLoopJob.perform_later(loop_state_id: loop_state.id)
    Rails.logger.info "Play loop job queued with state ID: #{loop_state.id}"
    true
  rescue StandardError => e
    # If state was created but job failed to enqueue, mark it as failed
    loop_state&.fail!("Failed to enqueue job: #{e.message}")
    Rails.logger.error "Failed to queue play loop job: #{e.message}"
    false
  end

  # Queue a village loop job with proper state management
  # Creates the GameLoopState before enqueueing the job for maximum robustness
  def self.queue_village_loop!(village_id, loop_cycle_id: nil, job_id: nil)
    unless GameLoopState.can_start_loop?("village_loop", village_id.to_s)
      Rails.logger.info "Village loop already running for Village ID: #{village_id}, not queuing new job"
      return false
    end

    # Create state atomically before enqueueing
    village_loop_state = GameLoopState.start_loop!("village_loop", village_id.to_s, job_id)
    VillageLoopJob.perform_later(village_id, loop_cycle_id: loop_cycle_id, village_loop_state_id: village_loop_state.id)
    Rails.logger.info "Village loop job queued for Village ID: #{village_id} with state ID: #{village_loop_state.id}"
    true
  rescue StandardError => e
    # If state was created but job failed to enqueue, mark it as failed
    village_loop_state&.fail!("Failed to enqueue job: #{e.message}")
    Rails.logger.error "Failed to queue village loop job for Village ID: #{village_id}: #{e.message}"
    false
  end

  # Legacy methods - kept for backward compatibility but not recommended
  # Use queue_* methods instead for external state management
  def self.start_play_loop!(job_id: nil)
    return nil unless GameLoopState.can_start_loop?("play_loop")
    GameLoopState.start_loop!("play_loop", nil, job_id)
  end

  def self.start_village_loop!(village_id, job_id: nil)
    return nil unless GameLoopState.can_start_loop?("village_loop", village_id.to_s)
    GameLoopState.start_loop!("village_loop", village_id.to_s, job_id)
  end
end
