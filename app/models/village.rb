class Village < ApplicationRecord
  belongs_to :user
  belongs_to :tile
  has_many :village_buildings
  has_many :buildings, through: :village_buildings

  validates :user_id, uniqueness: true
end
