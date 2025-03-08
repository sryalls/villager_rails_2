require 'rails_helper'

RSpec.feature "HexButton", type: :feature, js: true do
  let!(:user) { create(:user) }
  let!(:tile) { create(:tile) }

  before do
    sign_in user
    visit root_path
  end

  scenario "User sees 'Create Village' on an empty tile" do
    expect(page).to have_selector("[data-test-target='hex-button-create-#{tile.x}#{tile.y}']")  end

  scenario "User creates a village" do
    visit root_path
    expect(page).to have_selector("[data-test-target='hex-button-create-#{tile.x}#{tile.y}']")

    find("[data-test-target='hex-button-create-#{tile.x}#{tile.y}']").click
    page.find('h1', text: "#{user.username}'s Village")
    page.find('p', text: "Welcome to your village, #{user.username}!")
  end

  scenario "User cannot create another village if they already have one" do
    create(:village, user: user, tile: tile)
    visit root_path

    expect(page).not_to have_selector("[data-test-target='hex-button-create-#{tile.x}#{tile.y}']")
  end

  scenario "User navigates to an existing village" do
    village = create(:village, user: user, tile: tile)
    visit root_path
    expect(page).to have_selector("[data-test-target='hex-button-show-#{tile.x}#{tile.y}']")


    find("[data-test-target='hex-button-show-#{tile.x}#{tile.y}']").click

    page.find('h1', text: "#{user.username}'s Village")
    page.find('p', text: "Welcome to your village, #{user.username}!")
  end
end
