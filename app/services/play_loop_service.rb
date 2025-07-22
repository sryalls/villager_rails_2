class PlayLoopService < ApplicationService
  def initialize(loop_cycle_id: nil)
    @loop_cycle_id = loop_cycle_id
  end

  def call
    Rails.logger.info "Play loop service started at #{Time.current} (Cycle: #{@loop_cycle_id})"

    villages = Village.all
    return failure_result("No villages found") if villages.empty?

    villages_processed = process_all_villages(villages)

    Rails.logger.info "Play loop service completed at #{Time.current}"
    success_result("Successfully queued processing for #{villages_processed} villages", {
      villages_processed: villages_processed,
      processed_at: Time.current,
      loop_cycle_id: @loop_cycle_id
    })
  rescue StandardError => e
    Rails.logger.error "Error in play loop service: #{e.message}"
    failure_result("Failed to process play loop: #{e.message}")
  end

  private

  def process_all_villages(villages)
    villages.each do |village|
      # Pass the cycle ID so all jobs in this loop cycle are grouped together
      VillageLoopJob.perform_later(village.id, loop_cycle_id: @loop_cycle_id)
    end

    villages.count
  end
end
