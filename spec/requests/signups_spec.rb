require 'rails_helper'

RSpec.describe "Signups", type: :request do
  let(:organization) { create(:organization) }
  let(:activity) { create(:activity, organization: organization, title: "Lake Clean-up") }
  let(:shift) { create(:shift, activity: activity, capacity: 1) }
  let(:volunteer) { create(:membership, organization: organization).user }

  describe "POST /shifts/:shift_id/signup" do
    it "requires login" do
      post shift_signup_path(shift)

      expect(response).to redirect_to(new_user_session_path)
      expect(Signup.count).to eq(0)
    end

    it "confirms a member and returns to the activity" do
      sign_in volunteer

      post shift_signup_path(shift)

      expect(response).to redirect_to(activity_path(activity))
      expect(flash[:notice]).to eq("You are signed up for this shift.")
      expect(shift.signups.find_by(user: volunteer)).to be_confirmed
    end

    it "returns to the page the volunteer came from" do
      sign_in volunteer

      post shift_signup_path(shift), headers: { "HTTP_REFERER" => shift_url(shift) }

      expect(response).to redirect_to(shift_url(shift))
    end

    it "puts a member on the waiting list of a full shift" do
      create(:signup, shift: shift)
      sign_in volunteer

      post shift_signup_path(shift)

      expect(flash[:notice]).to eq("This shift is full. You are number 1 on the waiting list.")
      expect(shift.signups.find_by(user: volunteer)).to be_waitlisted
    end

    it "shows the reason when a business rule refuses the sign-up" do
      sign_in volunteer
      post shift_signup_path(shift)

      post shift_signup_path(shift)

      expect(flash[:alert]).to eq("You are already signed up for this shift.")
      expect(shift.signups.count).to eq(1)
    end

    it "refuses a non-member, even through a direct request" do
      sign_in create(:membership, :organizer).user

      post shift_signup_path(shift)

      expect(flash[:alert]).to eq("Join this organization before signing up for its shifts.")
      expect(Signup.count).to eq(0)
    end

    it "always signs up the logged-in user, whatever the parameters say" do
      other = create(:membership, organization: organization).user
      sign_in volunteer

      post shift_signup_path(shift), params: { user_id: other.id, signup: { user_id: other.id, status: "confirmed" } }

      expect(Signup.sole.user).to eq(volunteer)
    end
  end

  describe "GET /my/shifts" do
    it "lists the user's upcoming sign-ups, and past confirmed shifts with attendance separately" do
      sign_in volunteer
      create(:signup, shift: shift, user: volunteer)
      create(:signup, :cancelled, shift: create(:shift, activity: create(:activity, title: "Cancelled Shift")), user: volunteer)
      create(:signup, shift: create(:shift, :past, activity: create(:activity, title: "Past Shift")), user: volunteer)
      create(:signup, shift: create(:shift, activity: create(:activity, title: "Someone Else's Shift")))

      get signups_path

      page = Nokogiri::HTML(response.body)
      expect(page.css("ul.card-list").first.text).to include("Lake Clean-up", "Confirmed")
      expect(page.css("#past-shifts").text).to include("Past Shift", "Not recorded")
      expect(response.body).not_to include("Cancelled Shift", "Someone Else")
    end

    it "shows the waiting list position" do
      sign_in volunteer
      create(:signup, shift: shift)
      create(:signup, :waitlisted, shift: shift)
      create(:signup, :waitlisted, shift: shift, user: volunteer)

      get signups_path

      expect(response.body).to include("Waiting list #2")
    end

    it "lists upcoming shifts soonest first" do
      sign_in volunteer
      later = create(:shift, activity: create(:activity, title: "Later Shift"), starts_at: 5.days.from_now)
      sooner = create(:shift, activity: create(:activity, title: "Sooner Shift"), starts_at: 2.days.from_now)
      [ later, sooner ].each { |s| create(:signup, shift: s, user: volunteer) }

      get signups_path

      expect(response.body.index("Sooner Shift")).to be < response.body.index("Later Shift")
    end
  end

  describe "DELETE /shifts/:shift_id/signup" do
    before { sign_in volunteer }

    it "cancels a confirmed place and confirms the first volunteer waiting" do
      create(:signup, shift: shift, user: volunteer)
      waiting = create(:signup, :waitlisted, shift: shift)

      delete shift_signup_path(shift)

      expect(response).to redirect_to(activity_path(activity))
      expect(flash[:notice]).to eq("Your sign-up was cancelled. The next volunteer on the waiting list has been confirmed.")
      expect(waiting.reload).to be_confirmed
    end

    it "lets a volunteer leave the waiting list" do
      create(:signup, shift: shift)
      create(:signup, :waitlisted, shift: shift, user: volunteer)

      delete shift_signup_path(shift)

      expect(flash[:notice]).to eq("You left the waiting list.")
      expect(shift.signups.active.where(user: volunteer)).to be_empty
    end

    it "only ever cancels the logged-in user's own sign-up" do
      other = create(:signup, shift: shift)

      delete shift_signup_path(shift), params: { user_id: other.user_id }

      expect(flash[:alert]).to eq("You are not signed up for this shift.")
      expect(other.reload).to be_confirmed
    end

    it "refuses to cancel once the shift has started" do
      started = create(:shift, :past, activity: activity)
      create(:signup, shift: started, user: volunteer)

      delete shift_signup_path(started)

      expect(flash[:alert]).to eq("This shift has already started, so the sign-up can no longer be cancelled.")
      expect(started.signups.sole).to be_confirmed
    end
  end
end
