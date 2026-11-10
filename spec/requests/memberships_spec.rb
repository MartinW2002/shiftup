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

  describe "DELETE /organizations/:organization_id/membership" do
    it "requires login" do
      delete organization_membership_path(organization)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "lets a volunteer leave, after which the organization's pages are closed to them" do
      create(:membership, user: user, organization: organization)
      sign_in user

      delete organization_membership_path(organization)

      expect(response).to redirect_to(organizations_path)
      expect(flash[:notice]).to eq("You left #{organization.name}.")
      expect(user.member_of?(organization)).to be false

      get organization_path(organization)
      expect(flash[:alert]).to eq("Only members can see this organization's activities. Join it from the organizations page.")
    end

    it "lets a volunteer join again after leaving" do
      create(:membership, user: user, organization: organization)
      sign_in user
      delete organization_membership_path(organization)

      post organization_membership_path(organization)

      expect(user.membership_in(organization)).to be_volunteer
    end

    it "cancels the volunteer's upcoming shifts and waiting list places there, promoting the next in line" do
      create(:membership, user: user, organization: organization)
      activity = create(:activity, organization: organization)
      shift = create(:shift, activity: activity, capacity: 1)
      mine = create(:signup, user: user, shift: shift)
      next_in_line = create(:signup, :waitlisted, shift: shift)
      waiting = create(:signup, :waitlisted, user: user, shift: create(:shift, activity: activity))
      sign_in user

      delete organization_membership_path(organization)

      expect(response).to redirect_to(organizations_path)
      expect(flash[:notice]).to eq("You left #{organization.name}. Your 1 upcoming shift and 1 waiting list place there were cancelled.")
      expect([ mine.reload, waiting.reload ]).to all(be_cancelled)
      expect(next_in_line.reload).to be_confirmed
      expect(user.member_of?(organization)).to be false
    end

    it "stays a member and explains when a sign-up appears while leaving" do
      create(:membership, user: user, organization: organization)
      create(:signup, user: user, shift: create(:shift, activity: create(:activity, organization: organization)))
      allow_any_instance_of(ShiftCancellation).to receive(:call) # as if signed up again from another tab
      sign_in user

      delete organization_membership_path(organization)

      expect(response).to redirect_to(organization_path(organization))
      expect(flash[:alert]).to eq("You still have upcoming shifts or waiting list places in this organization. Please try again")
      expect(user.member_of?(organization)).to be true
    end

    it "refuses an organizer, even through a direct request" do
      create(:membership, :organizer, user: user, organization: organization)
      sign_in user

      delete organization_membership_path(organization)

      expect(flash[:alert]).to eq("Organizers cannot leave their organization.")
      expect(user.membership_in(organization)).to be_organizer
    end

    it "tells a non-member they are not a member" do
      sign_in user

      delete organization_membership_path(organization)

      expect(response).to redirect_to(organizations_path)
      expect(flash[:alert]).to eq("You are not a member of this organization.")
    end

    it "only ever removes the logged-in user's own membership" do
      other = create(:membership, organization: organization)
      create(:membership, user: user, organization: organization)
      sign_in user

      delete organization_membership_path(organization), params: { user_id: other.user_id }

      expect(Membership.exists?(other.id)).to be true
      expect(user.member_of?(organization)).to be false
    end
  end

  describe "the organization page" do
    def leave_confirmation
      Nokogiri::HTML(response.body).at_css("form[action='#{organization_membership_path(organization)}']")["data-turbo-confirm"]
    end

    it "warns in the leave confirmation which sign-ups will be cancelled" do
      create(:membership, user: user, organization: organization)
      activity = create(:activity, organization: organization)
      create(:signup, user: user, shift: create(:shift, activity: activity))
      create_list(:signup, 2, :waitlisted, user: user).each { |signup| signup.shift.update!(activity: activity) }
      sign_in user

      get organization_path(organization)

      expect(leave_confirmation).to eq("Leave #{organization.name}? Your 1 upcoming shift and 2 waiting list places there will be cancelled. You can join again later.")
    end

    it "keeps the leave confirmation short without upcoming sign-ups" do
      create(:membership, user: user, organization: organization)
      sign_in user

      get organization_path(organization)

      expect(leave_confirmation).to eq("Leave #{organization.name}? You can join again later.")
    end

    it "offers volunteers a Leave button but not organizers" do
      create(:membership, user: user, organization: organization)
      organizer = create(:membership, :organizer, organization: organization).user

      sign_in user
      get organization_path(organization)
      expect(response.body).to include("Leave organization")

      sign_in organizer
      get organization_path(organization)
      expect(response.body).not_to include("Leave organization")
    end
  end
end
