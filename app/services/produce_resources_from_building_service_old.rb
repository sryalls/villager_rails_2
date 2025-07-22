class ProduceResourcesFromBuildingService < ApplicationService
  def initialize(building_id, village, multiplier = 1, loop_cycle_id: nil)
    @building_id = building_id
    @multiplier = multiplier
    @village = village
    @building = nil
    @loop_cycle_id = loop_cycle_id
  end

  def call
    Rails.logger.info "Processing Building ID: #{@building_id} (Cycle: #{@loop_cycle_id})"

    @building = Building.find_by(id: @building_id)
    return failure_result("Building not found") unless @building

    # Check if already produced recently (data-state-based idempotency)
    if ResourceProduction.recently_produced?(@village, @building)
      Rails.logger.info "Building #{@building_id} already produced recently, skipping"
      return success_result("Resources already produced recently", {
        building_id: @building_id,
        skipped: true,
        loop_cycle_id: @loop_cycle_id
      })
    end

    result = process_building_outputs
    return failure_result(result.message, result.data) unless result.success

    Rails.logger.info "Finished processing Building: #{@building.name}"
    success_result("Successfully produced resources from #{@building.name}", result.data.merge(
      loop_cycle_id: @loop_cycle_id
    ))
  rescue StandardError => e
    Rails.logger.error "Error processing building #{@building_id}: #{e.message}"
    failure_result("Failed to produce resources: #{e.message}")
  end

  private

  def process_building_outputs
    resources_produced = []
    total_quantity = 0

    @building.building_outputs.each do |output|
      quantity_produced = output.quantity * @multiplier
      
      # Use atomic production recording (prevents duplicates)
      success = ResourceProduction.record_production!(
        @village,
        @building,
        output.resource,
        quantity_produced,
        @multiplier,
        @loop_cycle_id
      )
      
      if success
        resources_produced << {
          resource_name: output.resource.name,
          quantity: quantity_produced,
          new_total: VillageResource.find_by(@village, output.resource)&.count || quantity_produced
        }
        total_quantity += quantity_produced
      else
        Rails.logger.info "Skipped production for #{output.resource.name} - already produced recently"
      end
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
end
end
