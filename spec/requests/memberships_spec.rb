require 'rails_helper'

RSpec.describe "Memberships", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }

  describe "POST /organizations/:organization_id/membership" do
    it "requires login" do
      post organization_membership_path(organization)

      expect(response).to redirect_to(new_user_session_path)
      expect(Membership.count).to eq(0)
    end

    it "joins the organization as a volunteer" do
      sign_in user

      post organization_membership_path(organization)

      expect(response).to redirect_to(organization_path(organization))
      expect(user.membership_in(organization)).to be_volunteer
      expect(flash[:notice]).to eq("You joined #{organization.name} as a volunteer.")
    end

    it "ignores an attempt to join as an organizer" do
      sign_in user

      post organization_membership_path(organization), params: { role: "organizer", membership: { role: "organizer" } }

      expect(user.membership_in(organization)).to be_volunteer
    end

    it "refuses to join an organization twice" do
      create(:membership, :organizer, user: user, organization: organization)
      sign_in user

      expect {
        post organization_membership_path(organization)
      }.not_to change(Membership, :count)

      expect(flash[:alert]).to eq("You are already a member of this organization.")
      expect(user.membership_in(organization)).to be_organizer
    end

    it "returns not found for an unknown organization" do
      sign_in user

      post organization_membership_path(organization_id: 0)

      expect(response).to have_http_status(:not_found)
    end
  end
end
