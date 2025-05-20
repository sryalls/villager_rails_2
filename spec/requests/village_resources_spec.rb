require 'rails_helper'

RSpec.describe '/villages', type: :request do
  let(:user) { create(:user) }
  let(:village) { create(:village, user: user) }

  before { sign_in user }

  describe 'GET /villages/:id/resources_stream' do
    it 'returns successful turbo stream response' do
      get resources_stream_village_path(village),
          headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to be_successful
      expect(response.content_type).to include('text/vnd.turbo-stream.html')
    end

    it 'includes updated village resources' do
      resource = create(:resource, name: 'Wood')
      create(:village_resource, village: village, resource: resource, count: 50)

      get resources_stream_village_path(village),
          headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response.body).to include('Wood: 50')
      expect(response.body).to include('turbo-stream target="resources-list-content"')
    end

    it 'requires authentication' do
      sign_out user
      get resources_stream_village_path(village),
          headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'denies access to other users villages' do
      other_user = create(:user, email: 'other@example.com', username: 'otheruser')
      other_village = create(:village, user: other_user)

      get resources_stream_village_path(other_village),
          headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:forbidden)
    end

    it 'loads village resources with includes for efficiency' do
      resource = create(:resource, name: 'Stone')
      create(:village_resource, village: village, resource: resource, count: 25)

      get resources_stream_village_path(village),
          headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('text/vnd.turbo-stream.html')
    end
  end
end
