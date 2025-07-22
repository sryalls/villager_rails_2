class ProduceResourcesFromBuildingService < ApplicationService
  def initialize(building_id, village, multiplier = 1, job_id: nil)
    @building_id = building_id
    @multiplier = multiplier
    @village = village
    @building = nil
    @job_id = job_id || generate_job_id
  end

  def call
    # Check if this exact job has already been executed
    if JobExecution.job_executed?(@job_id, 'ProduceResourcesFromBuildingJob')
      Rails.logger.info "Job #{@job_id} already executed for Building ID: #{@building_id}, skipping"
      return success_result("Job already executed for building", { 
        building_id: @building_id, 
        skipped: true,
        job_id: @job_id
      })
    end

    Rails.logger.info "Processing Building ID: #{@building_id} (Job ID: #{@job_id})"

    @building = Building.find_by(id: @building_id)
    return record_failure("Building not found") unless @building

    result = process_building_outputs
    return record_failure(result.message, result.data) unless result.success

    # Record successful execution
    record_success(result.data)

    Rails.logger.info "Finished processing Building: #{@building.name}"
    success_result("Successfully produced resources from #{@building.name}", result.data.merge(job_id: @job_id))
  rescue StandardError => e
    Rails.logger.error "Error processing building #{@building_id}: #{e.message}"
    record_failure("Failed to produce resources: #{e.message}")
  end

  private

  def process_building_outputs
    resources_produced = []
    total_quantity = 0

    @building.building_outputs.each do |output|
      village_resource = VillageResource.find_or_create_by!(
        village: @village,
        resource: output.resource
      )
      quantity_produced = output.quantity * @multiplier
      village_resource.increment!(:count, quantity_produced)

      resources_produced << {
        resource_name: output.resource.name,
        quantity: quantity_produced,
        new_total: village_resource.reload.count
      }
      total_quantity += quantity_produced
    end

    ::OpenStruct.new(
      success: true,
      message: "Produced #{total_quantity} resources",
      data: {
        building_name: @building.name,
        multiplier: @multiplier,
        resources_produced: resources_produced,
        total_quantity: total_quantity
      }
    )
  rescue StandardError => e
    failure_result("Failed to process building outputs: #{e.message}")
  end

  def record_success(data)
    JobExecution.record_execution(
      @job_id,
      'ProduceResourcesFromBuildingJob',
      village: @village,
      building: @building,
      multiplier: @multiplier,
      resource_data: data,
      status: 'completed'
    )
  end

  def record_failure(message, data = {})
    JobExecution.record_execution(
      @job_id,
      'ProduceResourcesFromBuildingJob',
      village: @village,
      building: @building,
      multiplier: @multiplier,
      resource_data: data,
      status: 'failed'
    )
    failure_result(message, data.merge(job_id: @job_id))
  end

  def generate_job_id
    "building-#{@building_id}-#{@village.id}-#{@multiplier}-#{Time.current.to_i}"
  end
end
