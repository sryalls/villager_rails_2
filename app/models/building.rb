class Building < ApplicationRecord
  has_many :village_buildings
  has_many :villages, through: :village_buildings
  has_many :costs, dependent: :destroy
  has_many :tags, through: :costs
  has_many :building_outputs, dependent: :destroy

  validates :name, presence: true
end
