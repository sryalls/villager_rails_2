require 'rails_helper'

RSpec.describe VillageResource, type: :model do
  let(:village) { create(:village) }
  let(:resource) { create(:resource) }
  let(:village_resource) { build(:village_resource, village: village, resource: resource, count: 10) }

  context "validations" do
    it "is valid with valid attributes" do
      expect(village_resource).to be_valid
    end

    it "is not valid without a village" do
      village_resource.village = nil
      expect(village_resource).not_to be_valid
    end

    it "is not valid without a resource" do
      village_resource.resource = nil
      expect(village_resource).not_to be_valid
    end

    it "is not valid without a count" do
      village_resource.count = nil
      expect(village_resource).not_to be_valid
    end

    it "is not valid with a negative count" do
      village_resource.count = -1
      expect(village_resource).not_to be_valid
    end
  end

  context "associations" do
    it "belongs to a village" do
      expect(village_resource.village).to eq(village)
    end

    it "belongs to a resource" do
      expect(village_resource.resource).to eq(resource)
    end
  end
end
