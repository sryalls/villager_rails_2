class Building < ApplicationRecord
  has_many :village_buildings
  has_many :villages, through: :village_buildings
end
