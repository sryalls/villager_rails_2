require 'rails_helper'

RSpec.feature "VillageShow", type: :feature, js: true do
  let!(:user) { create(:user) }
  let!(:village) { create(:village, user: user) }
  let!(:building1) { create(:building, name: "Farm") }
  let!(:building2) { create(:building, name: "House") }
  let!(:building3) { create(:building, name: "Woodcutter") }

  before do
    sign_in user
    visit village_path(village)
    inject_csrf_token
  end

  scenario "User sees 'Build' button and dropdown of available buildings" do
    expect(page).to have_button("Build")
    find('[data-test="build-button"]').click
    expect(page).to have_select("village_building_building_id", with_options: ["Farm", "House", "Woodcutter"])
  end

  scenario "User builds a building" do
    find('[data-test="build-button"]').click
    select "Farm", from: "village_building_building_id"
    find('[data-test="form-submit-button"]').click
    within("#built-buildings") do
      expect(page).to have_content("Farm")
    end
  end

  scenario "User sees the list of built buildings" do
    village.buildings << building1
    village.buildings << building2
    visit village_path(village)
    within("#built-buildings") do
      expect(page).to have_content("Farm")
      expect(page).to have_content("House")
    end
  end
end
