class PlayLoopService < ApplicationService
  def initialize(job_id: nil)
    @job_id = job_id
    @loop_state = nil
  end

  def call
    # Check if a play loop is already running
    unless GameLoopState.can_start_loop?("play_loop")
      Rails.logger.info "Play loop already running, skipping this execution"
      return success_result("Play loop already running, execution skipped", { skipped: true })
    end

    # Start tracking this loop
    @loop_state = GameLoopState.start_loop!("play_loop", nil, @job_id)

    Rails.logger.info "Play loop service started at #{Time.current} (Loop ID: #{@loop_state.id})"

    begin
      villages = Village.all
      return failure_result("No villages found") unless villages.any?

      villages_processed = process_all_villages(villages)

      # Mark loop as completed
      @loop_state.complete!
      Rails.logger.info "Play loop service completed at #{Time.current} (Loop ID: #{@loop_state.id})"

      success_result("Successfully queued processing for #{villages_processed} villages", {
        villages_processed: villages_processed,
        processed_at: Time.current,
        loop_state_id: @loop_state.id
      })
    rescue StandardError => e
      # Mark loop as failed
      @loop_state&.fail!(e.message)
      Rails.logger.error "Play loop service failed: #{e.message} (Loop ID: #{@loop_state&.id})"
      failure_result("Failed to process play loop: #{e.message}")
    end
  end

  private

  def process_all_villages(villages)
    return 0 unless @loop_state

    # Get villages that have already been queued in this loop (for retry scenarios)
    already_queued_villages = @loop_state.queued_villages
    remaining_villages = villages - already_queued_villages

    Rails.logger.info "Processing #{remaining_villages.count}/#{villages.count} villages (#{already_queued_villages.count} already queued)"

    remaining_villages.each do |village|
      VillageLoopJob.perform_later(village.id, loop_cycle_id: @loop_state.id)
      @loop_state.mark_village_queued!(village)
    end

    villages.count
  end
end
