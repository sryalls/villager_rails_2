class ProduceResourcesFromBuildingService < ApplicationService
  def initialize(building_id, village, multiplier = 1, loop_cycle_id: nil)
    @building_id = building_id
    @multiplier = multiplier
    @village = village
    @building = nil
    @loop_cycle_id = loop_cycle_id
    @entity_tracker = loop_cycle_id ? GameLoopEntityTracker.new(loop_cycle_id) : nil
  end

  def call
    Rails.logger.info "Processing Building ID: #{@building_id} (Cycle: #{@loop_cycle_id})"

    @building = Building.find_by(id: @building_id)
    return failure_result("Building not found") unless @building

    # Individual resources are checked for idempotency during processing
    # (no need for building-level check since different resources can be produced independently)

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
      # Check if this specific resource was already produced by this building in this cycle
      if @entity_tracker&.resource_produced?(output.resource.id, @building.id, @village.id)
        Rails.logger.info "Resource #{output.resource.name} already produced by Building #{@building.id} in cycle #{@loop_cycle_id}, skipping"
        next
      end

      quantity_produced = output.quantity * @multiplier

      # Update the actual village resource directly (no need for ResourceProduction tracking)
      village_resource = VillageResource.find_or_create_by!(
        village: @village,
        resource: output.resource
      )
      village_resource.increment!(:count, quantity_produced)

      # Mark as produced in entity tracker for idempotency
      @entity_tracker&.mark_resource_produced!(output.resource.id, @building.id, @village.id)

      resources_produced << {
        resource_name: output.resource.name,
        quantity: quantity_produced,
        new_total: village_resource.count
      }
      total_quantity += quantity_produced

      Rails.logger.info "Produced #{quantity_produced} #{output.resource.name} (new total: #{village_resource.count})"
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
