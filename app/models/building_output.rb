class BuildingOutput < ApplicationRecord
  belongs_to :building
  belongs_to :resource

  validates :quantity, presence: true, numericality: { greater_than: 0 }
end
