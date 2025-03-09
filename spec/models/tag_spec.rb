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
  end
end
