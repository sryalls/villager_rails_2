class ProduceResourcesFromBuildingService < ApplicationService
  def initialize(building_id, village, multiplier = 1)
    @building_id = building_id
    @multiplier = multiplier
    @village = village
    @building = nil
  end

  def call
    Rails.logger.info "Processing Building ID: #{@building_id}"

    @building = Building.find_by(id: @building_id)
    return failure_result("Building not found") unless @building

    result = process_building_outputs
    return result unless result.success

    Rails.logger.info "Finished processing Building: #{@building.name}"
    success_result("Successfully produced resources from #{@building.name}", result.data)
  rescue StandardError => e
    Rails.logger.error "Error processing building #{@building_id}: #{e.message}"
    failure_result("Failed to produce resources: #{e.message}")
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
end
