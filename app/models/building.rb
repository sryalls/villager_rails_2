class Building < ApplicationRecord
  has_many :village_buildings
  has_many :villages, through: :village_buildings
  has_many :costs, dependent: :destroy
  has_many :tags, through: :costs

  validates :name, presence: true
end
