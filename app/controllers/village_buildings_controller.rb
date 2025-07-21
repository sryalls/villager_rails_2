class VillageBuildingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_village

  def create
    @building = Building.find(village_building_params[:building_id])
    resource_params = village_building_params[:resources]

    if VillageBuilding.sufficient_resources?(@village, resource_params)
      VillageBuilding.deduct_resources(@village, resource_params)
      @village.buildings << @building
      respond_to do |format|
        format.html { redirect_to @village, notice: I18n.t("flash.village_buildings.create.success") }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("flash", partial: "shared/flash", locals: { notice: I18n.t("flash.village_buildings.create.success") }),
            turbo_stream.update("resources-list-content", partial: "villages/resources_list", locals: { village_resources: @village.village_resources }),
            turbo_stream.replace("built-buildings", partial: "villages/built_buildings", locals: { buildings: @village.buildings })
          ]
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to @village, alert: I18n.t("flash.village_buildings.create.failure") }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: I18n.t("flash.village_buildings.create.failure") })
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
end
