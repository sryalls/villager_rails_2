module ApplicationHelper
  def calculate_spacer(tile)
    case tile.x
    when 1, 5
      1
    when 2, 4
      1
    when 3
      0
    else
      1
    end
  end
end
