require 'rails_helper'

RSpec.describe Tag, type: :model do
  let(:tag) { build(:tag) }

  context "validations" do
    it "is valid with valid attributes" do
      expect(tag).to be_valid
    end

    it "is not valid without a name" do
      tag.name = nil
      expect(tag).not_to be_valid
    end

    it "is not valid with a duplicate name" do
      create(:tag, name: tag.name)
      expect(tag).not_to be_valid
    end
  end

  context "associations" do
    let(:resource) { create(:resource) }
    let!(:tag) { create(:tag) }

    it "has and belongs to many resources" do
      resource.tags << tag
      expect(tag.resources).to include(resource)
    end

    context "with costs" do
      let(:building1) { create(:building) }
      let(:building2) { create(:building) }
      let!(:cost1) { create(:cost, building: building1, tag: tag, quantity: 50) }
      let!(:cost2) { create(:cost, building: building2, tag: tag, quantity: 10) }

      it "has many costs" do
        expect(tag.costs).to include(cost1, cost2)
      end

      it "has many buildings through costs" do
        expect(tag.buildings).to include(building1, building2)
      end
    end
  end
end
