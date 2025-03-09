require 'rails_helper'

RSpec.describe Resource, type: :model do
  let(:resource) { build(:resource) }
  let(:tag1) { create(:tag) }
  let(:tag2) { create(:tag) }

  context "validations" do
    it "is valid with valid attributes" do
      expect(resource).to be_valid
    end

    it "is not valid without a name" do
      resource.name = nil
      expect(resource).not_to be_valid
    end

    it "is not valid with a duplicate name" do
      create(:resource, name: resource.name)
      expect(resource).not_to be_valid
    end
  end

  context "associations" do
    let(:village) { create(:village) }
    let!(:village_resource) { create(:village_resource, village: village, resource: resource, count: 10) }

    it "has and belongs to many tags" do
      resource.tags << [ tag1, tag2 ]
      expect(resource.tags).to include(tag1, tag2)
    end

    it "has many villages through village_resources" do
      expect(resource.villages).to include(village)
    end

    it "has village_resources with counts" do
      expect(resource.village_resources).to include(village_resource)
      expect(village_resource.count).to eq(10)
    end
  end
end
