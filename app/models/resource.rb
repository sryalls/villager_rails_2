class Resource < ApplicationRecord
  has_and_belongs_to_many :tags
  has_many :village_resources
  has_many :villages, through: :village_resources

  validates :name, presence: true, uniqueness: true
end
