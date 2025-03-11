class Village < ApplicationRecord
  belongs_to :user
  belongs_to :tile
  has_many :village_buildings
  has_many :buildings, through: :village_buildings
  has_many :village_resources
  has_many :resources, through: :village_resources

  validates :user_id, uniqueness: true
  validates :tile_id, uniqueness: true

  def has_required_resources?(building)
    building.costs.each do |cost|
      total_amount = village_resources.joins(resource: :tags).where(tags: { id: cost.tag_id }).sum(:count)
      return false if total_amount < cost.quantity
    end
    true
  end
end
