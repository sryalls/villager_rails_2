require 'rails_helper'

RSpec.describe Village, type: :model do
  let(:village) { build(:village) }

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
  end

  context "associations" do
    let(:village) { create(:village) }
    let(:building1) { create(:building) }
    let(:building2) { create(:building) }

    it "belongs to a user" do
      expect(village.user).to be_present
    end

    it "has many buildings" do
      village.buildings << [building1, building2]
      expect(village.buildings).to include(building1, building2)
    end
  end
end
