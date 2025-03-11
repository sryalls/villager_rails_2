class VillagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_village, only: [ :show ]
  before_action :authorize_owner, only: [ :show ]

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
    @buildings = Building.all
    @village_resources = @village.village_resources.includes(:resource)
  end

  private

  def set_village
    @village = Village.find(params[:id])
  end

  def authorize_owner
    unless @village.user == current_user
      redirect_to root_path, alert: "You are not authorized to view this village."
    end
  end
end
