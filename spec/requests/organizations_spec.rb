require 'rails_helper'

RSpec.describe "Organizations", type: :request do
  let(:organization) { create(:organization, name: "Green Campus Society") }
  let(:other_organization) { create(:organization, name: "Harbour Tutoring Club") }
  let(:user) { create(:user) }

  describe "GET /organizations" do
    it "requires login" do
      get organizations_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "lists the user's organizations separately from the ones they can join" do
      create(:membership, user: user, organization: organization)
      other_organization
      sign_in user

      get organizations_path

      page = Nokogiri::HTML(response.body)
      expect(page.css("#my-organizations").text).to include("Green Campus Society")
      expect(page.css("#my-organizations").text).not_to include("Harbour Tutoring Club")
      expect(page.css("#other-organizations").text).to include("Harbour Tutoring Club")
      expect(page.css("#other-organizations form[action='#{organization_membership_path(other_organization)}']")).to be_present
      expect(page.css("form[action='#{organization_membership_path(organization)}']")).to be_empty
    end
  end

  describe "GET /organizations/:id" do
    it "requires login" do
      get organization_path(organization)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows members their organization's activities only" do
      create(:membership, user: user, organization: organization)
      create(:activity, organization: organization, title: "Lake Clean-up")
      create(:activity, organization: other_organization, title: "Weekend Maths Tutoring")
      sign_in user

      get organization_path(organization)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Lake Clean-up")
      expect(response.body).not_to include("Weekend Maths Tutoring")
    end

    it "denies access through a direct URL to non-members" do
      sign_in user

      get organization_path(organization)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Only members can see this organization's activities. Join it from the organizations page.")
    end

    it "denies an organizer of another organization" do
      create(:membership, :organizer, user: user, organization: other_organization)
      sign_in user

      get organization_path(organization)

      expect(response).to redirect_to(root_path)
    end

    it "sends a denied user back to the page they came from" do
      sign_in user

      get organization_path(organization), headers: { "HTTP_REFERER" => organizations_url }

      expect(response).to redirect_to(organizations_url)
    end

    it "answers 403 Forbidden to a denied non-HTML request" do
      sign_in user

      get organization_path(organization, format: :json)

      expect(response).to have_http_status(:forbidden)
    end

    it "returns not found for an unknown organization" do
      sign_in user

      get organization_path(id: 0)

      expect(response).to have_http_status(:not_found)
    end
  end
end
