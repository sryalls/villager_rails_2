class Tile < ApplicationRecord
  has_one :village

  validates :x, presence: true
  validates :y, presence: true
end
