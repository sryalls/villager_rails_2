# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# Ensure Devise is loaded
require 'devise'

# Create a user without a village
user_without_village = User.find_or_create_by!(email: 'example@example.com') do |user|
  user.username = 'exampleuser'
  user.password = 'password123'
  user.password_confirmation = 'password123'
end

# Create a user with a village
user_with_village = User.find_or_create_by!(email: 'villageuser@example.com') do |user|
  user.username = 'villageuser'
  user.password = 'password123'
  user.password_confirmation = 'password123'
end

# Create a tile for the village with coordinates
tile = Tile.find_or_create_by!(x: 2, y: 2)

# Create a village for the user
village = Village.find_or_create_by!(user: user_with_village, tile: tile)

# Create buildings
buildings = [
  { name: 'Farm' },
  { name: 'House' },
  { name: 'Woodcutter' },
  { name: 'Barracks' }
]

buildings.each do |building|
  Building.find_or_create_by!(building)
end

# Ensure the village has a house
house = Building.find_by(name: 'House')
VillageBuilding.find_or_create_by!(village: village, building: house)

# Create resources and tags
resources = [
  { name: 'Potatoes', tags: [ 'food' ] },
  { name: 'Lumber', tags: [ 'fuel', 'building materials' ] },
  { name: 'Stone Blocks', tags: [ 'building materials' ] },
  { name: 'Iron', tags: [ 'fortifying materials' ] }
]

resources.each do |resource_data|
  resource = Resource.find_or_create_by!(name: resource_data[:name])
  resource_data[:tags].each do |tag_name|
    tag = Tag.find_or_create_by!(name: tag_name)
    resource.tags << tag unless resource.tags.include?(tag)
  end
end

# Create costs for buildings
house = Building.find_by(name: 'House')
barracks = Building.find_by(name: 'Barracks')
woodcutter = Building.find_by(name: 'Woodcutter')

house.costs.find_or_create_by!(tag: Tag.find_by(name: 'building materials'), quantity: 10)
barracks.costs.find_or_create_by!(tag: Tag.find_by(name: 'building materials'), quantity: 50)
barracks.costs.find_or_create_by!(tag: Tag.find_by(name: 'fortifying materials'), quantity: 30)
woodcutter.costs.find_or_create_by!(tag: Tag.find_by(name: 'fuel'), quantity: 20)

# Create building outputs
lumber = Resource.find_by(name: 'Lumber')

BuildingOutput.find_or_create_by!(building: woodcutter, resource: lumber, quantity: 1)

potatoes = Resource.find_by(name: 'Potatoes')
farm = Building.find_by(name: 'Farm')

BuildingOutput.find_or_create_by!(building: farm, resource: potatoes, quantity: 1)


# Adjust village resources to test affordability
VillageResource.find_or_create_by!(village: village, resource: Resource.find_by(name: 'Lumber'), count: 60)
VillageResource.find_or_create_by!(village: village, resource: Resource.find_by(name: 'Stone Blocks'), count: 20)
VillageResource.find_or_create_by!(village: village, resource: Resource.find_by(name: 'Iron'), count: 10)
