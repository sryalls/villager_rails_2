class Cost < ApplicationRecord
  belongs_to :building
  belongs_to :tag

  validates :quantity, presence: true, numericality: { greater_than: 0 }
end
