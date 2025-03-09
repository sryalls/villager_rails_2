require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { build(:user) }

  context "validations" do
    it "is valid with valid attributes" do
      expect(user).to be_valid
    end
  end

  context "associations" do
    let(:user) { create(:user) }
    let!(:village) { create(:village, user: user) }

    it "has one village" do
      expect(user.village).to eq(village)
    end

    it "cannot have more than one village" do
      expect { create(:village, user: user) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
