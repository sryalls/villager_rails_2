class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @tiles = []
    tile_positions = [
      [1, 1], [1, 2], [1, 3],
      [2, 1], [2, 2], [2, 3], [2, 4],
      [3, 1], [3, 2], [3, 3], [3, 4], [3, 5],
      [4, 1], [4, 2], [4, 3], [4, 4],
      [5, 1], [5, 2], [5, 3]
    ]

    tile_positions.each do |x, y|
      tile = Tile.find_or_create_by(x: x, y: y)
      @tiles << tile
    end
  end
end
