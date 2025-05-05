class VillageLoopService
  def call(village_id)
    village = Village.find(village_id)

    Rails.logger.info "Processing Village: #{village.id}"
    village.village_buildings.select(&:has_building_outputs?).group_by(&:building_id).each do |building_id, village_buildings|
      ProduceResourcesFromBuildingJob.perform_later(building_id, village, village_buildings.count)
    end

    Rails.logger.info "Finished processing Village: #{village.id}"
  end
end
