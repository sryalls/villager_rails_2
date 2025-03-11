require 'rails_helper'

RSpec.feature "HexMap", type: :feature, js: true do
  let!(:user) { create(:user) }
  let!(:tile) { create(:tile) }
  let!(:other_user) { create(:user, email: 'other@example.com') }
  # let!(:village) { create(:village, user: user, tile: tile) }
  let!(:other_tile) { create(:tile, x: 2, y: 2) }
  let!(:other_village) { create(:village, user: other_user, tile: other_tile) }

  before do
    sign_in user
    visit root_path
    inject_csrf_token
  end

  scenario "User sees 'Create Village' on an empty tile" do
    expect(page).to have_selector("[data-test-target='hex-button-create-#{tile.x}#{tile.y}']")
  end

  scenario "User creates a village" do
    visit root_path
    expect(page).to have_selector("[data-test-target='hex-button-create-#{tile.x}#{tile.y}']")
    polygon = find("[data-test-target='hex-button-create-#{tile.x}#{tile.y}'] polygon")
    expect(polygon).to be_visible
    page.execute_script("arguments[0].dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));", polygon.native)
    page.find('h1', text: "#{user.username}'s Village")
    page.find('p', text: "Welcome to your village, #{user.username}!")
  end

  context "with a created village" do
    let!(:village) { create(:village, user: user, tile: tile) }

    scenario "User cannot create another village if they already have one" do
      visit root_path

      expect(page).not_to have_selector("[data-test-target='hex-button-create-#{other_tile.x}#{other_tile.y}']")
    end

    scenario "User navigates to own existing village" do
      visit root_path
      expect(page).to have_selector("[data-test-target='hex-button-show-#{tile.x}#{tile.y}']")
      polygon = find("[data-test-target='hex-button-show-#{tile.x}#{tile.y}'] polygon")
      expect(polygon).to be_visible
      page.execute_script("arguments[0].dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));", polygon.native)
      page.find('h1', text: "#{user.username}'s Village")
      page.find('p', text: "Welcome to your village, #{user.username}!")
    end

    scenario "User sees hex map with other user's village" do
      visit root_path
      within("[data-test-target='hex-button-show-#{other_village.tile.x}#{other_village.tile.y}']") do
        expect(page).to have_content("#{other_user.username}'s Village")
        expect(page).to have_css(".hexagon.village")
        expect(page).not_to have_css(".hexagon.no-village")
      end
    end

    scenario "Hex button for other user's village is not clickable" do
      visit root_path
      polygon = find("[data-test-target='hex-button-show-#{other_village.tile.x}#{other_village.tile.y}'] polygon")
      expect(polygon).to be_visible
      has_onclick = page.evaluate_script('arguments[0].onclick !== null', polygon.native)
      expect(has_onclick).to be_falsey
    end
  end
end
