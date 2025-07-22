class PlayLoopService < ApplicationService
  def initialize(*args, job_id: nil)
    # No initialization needed for this service
    @args = args
    @job_id = job_id || generate_job_id
  end

  def call
    # Check if this exact job has already been executed
    if JobExecution.job_executed?(@job_id, 'PlayLoopJob')
      Rails.logger.info "Job #{@job_id} already executed for play loop, skipping"
      return success_result("Play loop job already executed", { 
        skipped: true,
        job_id: @job_id
      })
    end

    Rails.logger.info "Play loop service started at #{Time.current} (Job ID: #{@job_id})"

    villages = Village.all
    return record_failure("No villages found") if villages.empty?

    villages_processed = process_all_villages(villages)

    # Record successful execution
    record_success(villages_processed)

    Rails.logger.info "Play loop service completed at #{Time.current}"
    success_result("Successfully queued processing for #{villages_processed} villages", {
      villages_processed: villages_processed,
      processed_at: Time.current,
      job_id: @job_id
    })
  rescue StandardError => e
    Rails.logger.error "Error in play loop service: #{e.message}"
    record_failure("Failed to process play loop: #{e.message}")
  end

  private

  def process_all_villages(villages)
    jobs_queued = []
    villages.each do |village|
      village_job_id = "#{@job_id}-village-#{village.id}"
      
      # Only queue if not already processed for idempotency
      unless JobExecution.job_executed?(village_job_id, 'VillageLoopJob')
        VillageLoopJob.perform_later(village.id, village_job_id)
        jobs_queued << { village_id: village.id, job_id: village_job_id }
      end
    end

    villages.count
  end

  def record_success(villages_processed)
    JobExecution.record_execution(
      @job_id,
      'PlayLoopJob',
      resource_data: { villages_processed: villages_processed },
      status: 'completed'
    )
  end

  def record_failure(message, data = {})
    JobExecution.record_execution(
      @job_id,
      'PlayLoopJob',
      resource_data: data,
      status: 'failed'
    )
    failure_result(message, data.merge(job_id: @job_id))
  end

  def generate_job_id
    "play-loop-#{Time.current.to_i}"
  end
end
