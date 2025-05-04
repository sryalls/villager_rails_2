require 'rails_helper'

RSpec.describe BuildingOutput, type: :model do
  let(:building) { create(:building) }
  let(:resource) { create(:resource) }
  let(:building_output) { build(:building_output, building: building, resource: resource) }

  context "validations" do
    it "is valid with valid attributes" do
      expect(building_output).to be_valid
    end

    it "is not valid without a quantity" do
      building_output.quantity = nil
      expect(building_output).not_to be_valid
    end

    it "is not valid with a non-numeric quantity" do
      building_output.quantity = "abc"
      expect(building_output).not_to be_valid
    end

    it "is not valid with a quantity less than zero" do
      building_output.quantity = -1
      expect(building_output).not_to be_valid
    end
  end

  context "associations" do
    it "belongs to a building" do
      expect(building_output).to respond_to(:building)
    end

    it "belongs to a resource" do
      expect(building_output).to respond_to(:resource)
    end
  end
end
