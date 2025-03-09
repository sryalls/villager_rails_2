class VillageResource < ApplicationRecord
  belongs_to :village
  belongs_to :resource

  validates :count, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
