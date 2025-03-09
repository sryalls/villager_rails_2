class VillageBuildingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_village

  def create
    @building = Building.find(params[:village_building][:building_id])
    @village.buildings << @building
    respond_to do |format|
      format.html { redirect_to @village, notice: "Building was successfully added." }
      format.turbo_stream
    end
  end

  private

  def set_village
    @village = Village.find(params[:village_id])
  end
end
