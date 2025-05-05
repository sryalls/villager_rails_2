class ProduceResourcesFromBuildingService
  def initialize(building_id, village, multiplier = 1)
    @building = Building.find(building_id)
    @multiplier = multiplier
    @village = village
  end

  def call
    Rails.logger.info "Processing Building: #{@building.name}"
    process_building_outputs
    Rails.logger.info "Finished processing Building: #{@building.name}"
  end

  private

  def process_building_outputs
    @building.building_outputs.each do |output|
      village_resource = VillageResource.find_or_create_by!(
        village: @village,
        resource: output.resource
      )
      village_resource.increment!(:count, output.quantity * @multiplier)
    end
  end
end
