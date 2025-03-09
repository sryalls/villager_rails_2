require 'rails_helper'

RSpec.describe Village, type: :model do
  let(:user) { create(:user) }
  let(:tile) { create(:tile) }
  let(:village) { build(:village, user: user, tile: tile) }

  context "validations" do
    it "is valid with valid attributes" do
      expect(village).to be_valid
    end

    it "is not valid without a user" do
      village.user = nil
      expect(village).not_to be_valid
    end

    it "is not valid without a tile" do
      village.tile = nil
      expect(village).not_to be_valid
    end

    it "is not valid with a duplicate user_id" do
      create(:village, user: village.user)
      expect(village).not_to be_valid
    end

    it "is not valid with a duplicate tile_id" do
      create(:village, tile: village.tile)
      expect(village).not_to be_valid
    end
  end

  context "associations" do
    let(:village) { create(:village) }
    let(:building1) { create(:building) }
    let(:building2) { create(:building) }
    let(:resource1) { create(:resource) }
    let(:resource2) { create(:resource) }
    let!(:village_resource1) { create(:village_resource, village: village, resource: resource1, count: 10) }
    let!(:village_resource2) { create(:village_resource, village: village, resource: resource2, count: 20) }

    it "belongs to a user" do
      expect(village.user).to be_present
    end

    it "has many buildings" do
      village.buildings << [ building1, building2 ]
      expect(village.buildings).to include(building1, building2)
    end

    it "has many resources through village_resources" do
      expect(village.resources).to include(resource1, resource2)
    end

    it "has village_resources with counts" do
      expect(village.village_resources).to include(village_resource1, village_resource2)
      expect(village_resource1.count).to eq(10)
      expect(village_resource2.count).to eq(20)
    end
  end
end
