class Village < ApplicationRecord
  belongs_to :user
  belongs_to :tile

  validates :user_id, uniqueness: true
end
