require 'rails_helper'

RSpec.describe VillageBuilding, type: :model do
  let(:village) { create(:village) }
  let(:building) { create(:building) }
  let(:village_building) { build(:village_building, village: village, building: building) }

  context "validations" do
    it "is valid with valid attributes" do
      expect(village_building).to be_valid
    end

    context "when village is nil" do
      before { village_building.village = nil }

      it "is not valid without a village" do
        expect(village_building).not_to be_valid
      end
    end

    context "when building is nil" do
      before { village_building.building = nil }

      it "is not valid without a building" do
        expect(village_building).not_to be_valid
      end
    end
  end

  context "associations" do
    let(:village) { create(:village) }
    let(:building) { create(:building) }
    let(:village_building) { create(:village_building, village: village, building: building) }

    it "belongs to a village" do
      expect(village_building.village).to eq(village)
    end

    it "belongs to a building" do
      expect(village_building.building).to eq(building)
    end
  end
end
