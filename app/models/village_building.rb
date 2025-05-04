class VillageBuilding < ApplicationRecord
  belongs_to :village
  belongs_to :building

  def self.sufficient_resources?(village, resource_params)
    resource_params.to_h.all? do |resource_id, quantity|
      village_resource = village.village_resources.find_by(resource_id: resource_id)
      village_resource && village_resource.count >= quantity.to_i
    end
  end

  def self.deduct_resources(village, resource_params)
    resource_params.to_h.each do |resource_id, quantity|
      village_resource = village.village_resources.find_by(resource_id: resource_id)
      village_resource.update(count: village_resource.count - quantity.to_i)
    end
  end
end
