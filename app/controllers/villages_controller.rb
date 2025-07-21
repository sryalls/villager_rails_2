class VillagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_village, only: [ :show, :resource_selectors, :resources_stream ]
  before_action :authorize_owner, only: [ :show, :resources_stream ]

  def create
    if current_user.village
      render json: { status: "error", errors: [ "User already has a village" ] }, status: :unprocessable_entity
      return
    end

    @village = Village.new(tile_id: params[:tile_id], user_id: current_user.id)

    if @village.save
      respond_to do |format|
        format.html { redirect_to @village, notice: "Village was successfully created." }
        format.json { render json: { redirect_url: village_url(@village) }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json { render json: @village.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
    @village.reload # Ensure we have fresh data
    @buildings = Building.all
    @village_resources = @village.village_resources.includes(:resource)
  end

  def resource_selectors
    @building = Building.find(params[:building_id])
    render turbo_stream: turbo_stream.replace("resource-selectors-frame", partial: "resource_selectors", locals: { building: @building, village: @village })
  end

  def resources_stream
    # Reload village and its associations to get the latest data
    @village.reload
    @village_resources = @village.village_resources.includes(:resource)

    # Prevent caching to ensure fresh data
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_village
    @village = Village.find(params[:id] || params[:village_id])
  end

  def authorize_owner
    unless @village.user == current_user
      respond_to do |format|
        format.html { redirect_to root_path, alert: "You are not authorized to view this village." }
        format.any { head :forbidden }
      end
    end
  end
end
