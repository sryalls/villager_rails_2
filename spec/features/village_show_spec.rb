require 'rails_helper'

RSpec.feature "VillageShow", type: :feature, js: true do
  let!(:user) { create(:user) }
  let!(:village) { create(:village, user: user) }
  let!(:building1) { create(:building, name: "Farm") }
  let!(:building2) { create(:building, name: "House") }
  let!(:building3) { create(:building, name: "Woodcutter") }
  let!(:tag1) { create(:tag, name: "Building Material") }
  let!(:tag2) { create(:tag, name: "Furniture") }
  let!(:cost1) { create(:cost, building: building1, tag: tag1, quantity: 50) }
  let!(:cost2) { create(:cost, building: building2, tag: tag2, quantity: 10) }
  let!(:resource1) { create(:resource, name: "Wood") }
  let!(:resource2) { create(:resource, name: "Stone") }
  let!(:village_resource1) { create(:village_resource, village: village, resource: resource1, count: 100) }
  let!(:village_resource2) { create(:village_resource, village: village, resource: resource2, count: 5) } # Not enough for House

  before do
    resource1.tags << tag1
    resource2.tags << tag2
    sign_in user
    visit village_path(village)
    inject_csrf_token
  end

  scenario "User sees 'Build' button and radio list of available buildings" do
    expect(page).to have_button("Build")
    find('[data-test="build-button"]').click
    expect(page).to have_selector("input[type=radio][name='village_building[building_id]'][value='#{building1.id}']:not([disabled])")
    expect(page).to have_selector("input[type=radio][name='village_building[building_id]'][value='#{building2.id}'][disabled]")
    expect(page).to have_selector("input[type=radio][name='village_building[building_id]'][value='#{building3.id}']:not([disabled])")
    expect(page).to have_content("Farm")
    expect(page).to have_content("House")
    expect(page).to have_content("Woodcutter")
    expect(page).to have_content("50 Building Material")
    expect(page).to have_content("10 Furniture")
  end

  scenario "User builds a building" do
    find('[data-test="build-button"]').click
    choose "Farm"
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

  scenario "User sees the list of resources with quantities" do
    visit village_path(village)
    within('[data-test="resources-list"]') do
      expect(page).to have_content("Wood: 100")
      expect(page).to have_content("Stone: 5")
    end
  end
end
