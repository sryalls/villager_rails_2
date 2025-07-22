class PlayLoopSchedulerJob < ApplicationJob
  queue_as :default

  def perform
    # Use GameLoopManager for proper state management and atomic job queuing
    success = GameLoopManager.queue_play_loop!(job_id: generate_scheduler_job_id)
    
    if success
      Rails.logger.info "Play loop successfully scheduled"
    else
      Rails.logger.info "Play loop not scheduled (already running or failed)"
    end
  end

  private

  def generate_scheduler_job_id
    "scheduler-#{Time.current.to_i}-#{SecureRandom.hex(4)}"
  end
end
