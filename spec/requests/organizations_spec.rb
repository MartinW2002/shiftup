require 'rails_helper'

RSpec.describe "Organizations", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }

  it "requires login" do
    get organization_path(organization)

    expect(response).to redirect_to(new_user_session_path)
  end

  it "shows the organization to its members" do
    create(:membership, user: user, organization: organization)
    sign_in user

    get organization_path(organization)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(organization.name)
  end

  it "denies access through a direct URL to non-members" do
    sign_in user

    get organization_path(organization)

    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq("You are not authorized to perform this action.")
  end
end
