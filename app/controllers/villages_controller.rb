class VillagesController < ApplicationController
  before_action :authenticate_user!

  def create
    if current_user.village
      render json: { status: 'error', errors: ['User already has a village'] }, status: :unprocessable_entity
      return
    end

    @village = Village.new(tile_id: params[:tile_id], user_id: current_user.id)

    if @village.save
      render json: { redirect_url: village_path(@village) }, status: :created
    else
      render json: { status: 'error', errors: @village.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    @village = Village.find(params[:id])
  end
end
