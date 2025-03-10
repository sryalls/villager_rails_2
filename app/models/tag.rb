class Tag < ApplicationRecord
  has_and_belongs_to_many :resources
  has_many :costs, dependent: :destroy
  has_many :buildings, through: :costs

  validates :name, presence: true, uniqueness: true
end
