class Village < ApplicationRecord
  belongs_to :user
  belongs_to :tile
  has_many :village_buildings
  has_many :buildings, through: :village_buildings
  has_many :village_resources
  has_many :resources, through: :village_resources

  validates :user_id, uniqueness: true
  validates :tile_id, uniqueness: true
end
