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
  shared_context 'with buildings and resources' do
    let(:building1) { create(:building) }
    let(:building2) { create(:building) }
    let(:resource1) { create(:resource) }
    let(:resource2) { create(:resource) }

    before do
      village.buildings << [ building1, building2 ]
    end
  end

  context "associations" do
    include_context 'with buildings and resources'

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

  describe '#has_required_resources?' do
    include_context 'with buildings and resources'
    let(:tag1) { create(:tag, name: 'wood') }
    let(:tag2) { create(:tag, name: 'stone') }
    before do
      resource1.tags << tag1
      resource2.tags << tag2
    end

    context 'when the village has enough resources' do
      before do
        create(:village_resource, village: village, resource: resource1, count: 100)
        create(:cost, building: building1, tag: tag1, quantity: 50)
      end

      it 'returns true' do
        expect(village.has_required_resources?(building1)).to be true
      end
    end

    context 'when the village does not have enough resources' do
      before do
        create(:village_resource, village: village, resource: resource1, count: 30)
        create(:cost, building: building1, tag: tag1, quantity: 50)
      end

      it 'returns false' do
        expect(village.has_required_resources?(building1)).to be false
      end
    end

    context 'when the village does not have the required resource tag' do
      let(:other_tag) { create(:tag, name: 'iron') }
      let(:other_resource) { create(:resource) }

      before do
        other_resource.tags << other_tag
        create(:village_resource, village: village, resource: other_resource, count: 100)
        create(:cost, building: building1, tag: tag1, quantity: 50)
      end

      it 'returns false' do
        expect(village.has_required_resources?(building1)).to be false
      end
    end

    context 'when the building has multiple required tags and the village has enough of both' do
      before do
        create(:village_resource, village: village, resource: resource1, count: 100)
        create(:village_resource, village: village, resource: resource2, count: 100)
        create(:cost, building: building1, tag: tag1, quantity: 50)
        create(:cost, building: building1, tag: tag2, quantity: 50)
      end

      it 'returns true' do
        expect(village.has_required_resources?(building1)).to be true
      end
    end

    context 'when the building has multiple required tags and the village only has enough of one' do
      before do
        create(:village_resource, village: village, resource: resource1, count: 100)
        create(:village_resource, village: village, resource: resource2, count: 30)
        create(:cost, building: building1, tag: tag1, quantity: 50)
        create(:cost, building: building1, tag: tag2, quantity: 50)
      end

      it 'returns false' do
        expect(village.has_required_resources?(building1)).to be false
      end
    end

    context 'when the village has two resources of the same tag and can only make up the cost by combining them' do
      let(:resource3) { create(:resource) }

      before do
        resource3.tags << tag1
        create(:village_resource, village: village, resource: resource1, count: 30)
        create(:village_resource, village: village, resource: resource3, count: 20)
        create(:cost, building: building1, tag: tag1, quantity: 50)
      end

      it 'returns true' do
        expect(village.has_required_resources?(building1)).to be true
      end
    end
  end
end
