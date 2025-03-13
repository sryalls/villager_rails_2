class VillageBuildingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_village

  def create
    @building = Building.find(village_building_params[:building_id])
    resource_params = village_building_params[:resources]

    if sufficient_resources?(resource_params)
      deduct_resources(resource_params)
      @village.buildings << @building
      respond_to do |format|
        format.html { redirect_to @village, notice: "Building was successfully added." }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("flash", partial: "shared/flash", locals: { notice: "Building was successfully added." }),
            turbo_stream.replace("resources-list", partial: "villages/resources_list", locals: { village_resources: @village.village_resources }),
            turbo_stream.replace("built-buildings", partial: "villages/built_buildings", locals: { buildings: @village.buildings })
          ]
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to @village, alert: "Insufficient resources to build this building." }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: "Insufficient resources to build this building." })
          ]
        end
      end
    end
  end

  private

  def set_village
    @village = Village.find(params[:village_id])
  end

  def village_building_params
    params.require(:village_building).permit(:building_id, resources: {})
  end

  def sufficient_resources?(resource_params)
    resource_params.to_h.all? do |resource_id, quantity|
      village_resource = @village.village_resources.find_by(resource_id: resource_id)
      village_resource && village_resource.count >= quantity.to_i
    end
  end

  def deduct_resources(resource_params)
    raise "a"
    resource_params.to_h.each do |resource_id, quantity|
      village_resource = @village.village_resources.find_by(resource_id: resource_id)
      village_resource.update(count: village_resource.count - quantity.to_i)
    end
  end
end
