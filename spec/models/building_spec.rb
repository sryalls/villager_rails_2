require 'rails_helper'

RSpec.describe Building, type: :model do
  let(:building) { build(:building) }

  context "validations" do
    it "is valid with valid attributes" do
      expect(building).to be_valid
    end

    it "is not valid without a name" do
      building.name = nil
      expect(building).not_to be_valid
    end
  end

  context "associations" do
    let(:village) { create(:village) }
    let!(:village_building1) { create(:village_building, building: building, village: village) }
    let!(:village_building2) { create(:village_building, building: building, village: village) }

    it "has many village_buildings" do
      expect(building.village_buildings).to include(village_building1, village_building2)
    end

    context "with multiple villages" do
      let(:village1) { create(:village) }
      let(:village2) { create(:village) }
      let!(:village_building1) { create(:village_building, building: building, village: village1) }
      let!(:village_building2) { create(:village_building, building: building, village: village2) }

      it "has many villages through village_buildings" do
        expect(building.villages).to include(village1, village2)
      end
    end
  end
end
