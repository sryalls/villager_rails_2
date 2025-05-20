require 'rails_helper'

RSpec.describe 'Village Auto Refresh', type: :system, js: true do
  let(:user) { create(:user) }
  let(:village) { create(:village, user: user) }
  let(:resource) { create(:resource, name: 'Wood') }

  before do
    sign_in user
    create(:village_resource, village: village, resource: resource, count: 10)
  end

  it 'displays initial resource counts' do
    visit village_path(village)

    expect(page).to have_content('Wood: 10')
    expect(page).to have_css('#resources-list-content')
  end

  it 'automatically updates resources when backend changes' do
    visit village_path(village)

    expect(page).to have_content('Wood: 10')

    # Simulate backend resource update (like a Sidekiq job might do)
    village_resource = village.village_resources.find_by(resource: resource)
    village_resource.update!(count: 25)

    # Wait for auto-refresh (polling happens every second)
    expect(page).to have_content('Wood: 25', wait: 5)
    expect(page).not_to have_content('Wood: 10')
  end

  it 'continues polling after resource updates' do
    visit village_path(village)

    # First update
    village_resource = village.village_resources.find_by(resource: resource)
    village_resource.update!(count: 20)
    expect(page).to have_content('Wood: 20', wait: 5)

    # Wait a bit to ensure polling cycle completes
    sleep(2)

    # Second update to ensure polling continues
    village_resource.update!(count: 35)
    expect(page).to have_content('Wood: 35', wait: 8)
  end

  it 'handles multiple resources correctly' do
    stone = create(:resource, name: 'Stone')
    create(:village_resource, village: village, resource: stone, count: 5)

    visit village_path(village)

    expect(page).to have_content('Wood: 10')
    expect(page).to have_content('Stone: 5')

    # Update both resources
    village.village_resources.find_by(resource: resource).update!(count: 15)
    village.village_resources.find_by(resource: stone).update!(count: 8)

    expect(page).to have_content('Wood: 15', wait: 5)
    expect(page).to have_content('Stone: 8', wait: 5)
  end

  context 'when user is not authenticated' do
    it 'redirects to login page' do
      sign_out user
      visit village_path(village)

      expect(page).to have_current_path(new_user_session_path)
    end
  end

  context 'when user does not own the village' do
    let(:other_user) { create(:user, email: 'other@example.com', username: 'otheruser') }
    let(:other_village) { create(:village, user: other_user) }

    it 'shows access denied' do
      visit village_path(other_village)

      # Check that user is redirected to root or sees error message
      expect(page).to have_current_path(root_path).or have_content("You are not authorized to view this village")
    end
  end
end
