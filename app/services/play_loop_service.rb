class PlayLoopService < ApplicationService
  def initialize(loop_state:)
    @loop_state = loop_state
  end

  def call
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
      @loop_state.fail!(e.message)
      Rails.logger.error "Play loop service failed: #{e.message} (Loop ID: #{@loop_state.id})"
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
      # Use GameLoopManager for external state management
      if GameLoopManager.queue_village_loop!(village.id, loop_cycle_id: @loop_state.id)
        @loop_state.mark_village_queued!(village)
      else
        Rails.logger.warn "Failed to queue village loop for Village ID: #{village.id}"
      end
    end

    villages.count
  end
end
