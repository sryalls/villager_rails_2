require 'rails_helper'

RSpec.describe Cost, type: :model do
  let(:building) { create(:building) }
  let(:tag) { create(:tag) }
  let(:cost) { build(:cost, building: building, tag: tag) }

  context "validations" do
    it "is valid with valid attributes" do
      expect(cost).to be_valid
    end

    it "is not valid without a quantity" do
      cost.quantity = nil
      expect(cost).not_to be_valid
    end

    it "is not valid with a non-numeric quantity" do
      cost.quantity = "abc"
      expect(cost).not_to be_valid
    end

    it "is not valid with a quantity less than or equal to zero" do
      cost.quantity = 0
      expect(cost).not_to be_valid
    end
  end

  context "associations" do
    it "belongs to a building" do
      expect(cost).to respond_to(:building)
    end

    it "belongs to a tag" do
      expect(cost).to respond_to(:tag)
    end
  end
end
