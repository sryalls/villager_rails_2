class Village < ApplicationRecord
  belongs_to :user
  belongs_to :tile
end
