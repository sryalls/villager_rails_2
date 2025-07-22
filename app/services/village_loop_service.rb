class VillageLoopService < ApplicationService
  def initialize(village_id, job_id: nil)
    @village_id = village_id
    @job_id = job_id || generate_job_id
  end

  def call
    # Check if this exact job has already been executed
    if JobExecution.job_executed?(@job_id, 'VillageLoopJob')
      Rails.logger.info "Job #{@job_id} already executed for Village ID: #{@village_id}, skipping"
      return success_result("Job already executed for village", { 
        village_id: @village_id, 
        skipped: true,
        job_id: @job_id
      })
    end

    Rails.logger.info "Processing Village ID: #{@village_id} (Job ID: #{@job_id})"

    village = Village.find_by(id: @village_id)
    return record_failure("Village not found") unless village

    buildings_processed = process_village_buildings(village)

    # Record successful execution
    record_success(village, buildings_processed)

    Rails.logger.info "Finished processing Village: #{village.id}"
    success_result("Successfully processed #{buildings_processed} building types", {
      village_id: village.id,
      buildings_processed: buildings_processed,
      job_id: @job_id
    })
  rescue StandardError => e
    Rails.logger.error "Error processing village #{@village_id}: #{e.message}"
    record_failure("Failed to process village: #{e.message}")
  end

  private

  def process_village_buildings(village)
    building_groups = village.village_buildings
                           .select(&:has_building_outputs?)
                           .group_by(&:building_id)

    jobs_queued = []
    building_groups.each do |building_id, village_buildings|
      building_job_id = "#{@job_id}-building-#{building_id}"
      
      # Only queue if not already processed for idempotency
      unless JobExecution.job_executed?(building_job_id, 'ProduceResourcesFromBuildingJob')
        ProduceResourcesFromBuildingJob.perform_later(building_id, village, village_buildings.count, building_job_id)
        jobs_queued << {
          building_id: building_id,
          multiplier: village_buildings.count,
          job_id: building_job_id
        }
      end
    end

    building_groups.count
  end

  def record_success(village, buildings_processed)
    JobExecution.record_execution(
      @job_id,
      'VillageLoopJob',
      village: village,
      resource_data: { buildings_processed: buildings_processed },
      status: 'completed'
    )
  end

  def record_failure(message, data = {})
    village = Village.find_by(id: @village_id)
    JobExecution.record_execution(
      @job_id,
      'VillageLoopJob',
      village: village,
      resource_data: data,
      status: 'failed'
    )
    failure_result(message, data.merge(job_id: @job_id))
  end

  def generate_job_id
    "village-#{@village_id}-#{Time.current.to_i}"
  end
end
