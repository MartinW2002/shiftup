require 'rails_helper'

RSpec.describe "Removals", type: :request do
  let(:organization) { create(:organization) }
  let(:shift) { create(:shift, activity: create(:activity, organization: organization), capacity: 1) }
  let(:organizer) { create(:membership, :organizer, organization: organization).user }
  let(:signup) { create(:signup, shift: shift, user: create(:user, name: "Victor Volunteer")) }

  describe "POST /signups/:signup_id/removal" do
    it "lets an organizer remove a confirmed volunteer and names who moved up" do
      create(:signup, :waitlisted, shift: shift, user: create(:user, name: "Wendy Volunteer"))
      sign_in organizer

      post signup_removal_path(signup)

      expect(response).to redirect_to(shift_path(shift))
      expect(flash[:notice]).to eq("Victor Volunteer was removed from this shift. Wendy Volunteer moved up from the waiting list.")
      expect(signup.reload).to be_cancelled
    end

    it "says so when nobody was waiting" do
      sign_in organizer

      post signup_removal_path(signup)

      expect(flash[:notice]).to eq("Victor Volunteer was removed from this shift.")
    end

    it "removes someone from the waiting list" do
      waiting = create(:signup, :waitlisted, shift: shift, user: create(:user, name: "Wendy Volunteer"))
      sign_in organizer

      post signup_removal_path(waiting)

      expect(flash[:notice]).to eq("Wendy Volunteer was removed from the waiting list.")
      expect(waiting.reload).to be_cancelled
    end

    it "explains when the shift has already started" do
      started = create(:signup, shift: create(:shift, :past, activity: shift.activity))
      sign_in organizer

      post signup_removal_path(started)

      expect(flash[:alert]).to eq("This shift has already started, so nobody can be removed. Record attendance instead.")
      expect(started.reload).to be_confirmed
    end

    it "denies volunteers, including the volunteer themselves" do
      sign_in signup.user

      post signup_removal_path(signup)

      expect(flash[:alert]).to eq("Only this organization's organizers can remove volunteers from a shift.")
      expect(signup.reload).to be_confirmed
    end

    it "denies an organizer of another organization using a direct URL" do
      sign_in create(:membership, :organizer).user

      post signup_removal_path(signup)

      expect(response).to redirect_to(root_path)
      expect(signup.reload).to be_confirmed
    end

    it "requires login" do
      post signup_removal_path(signup)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "the shift page" do
    it "offers organizers a Remove button with a warning for each confirmed and waiting volunteer" do
      signup
      waiting = create(:signup, :waitlisted, shift: shift, user: create(:user, name: "Wendy Volunteer"))
      sign_in organizer

      get shift_path(shift)

      page = Nokogiri::HTML(response.body)
      confirm = ->(record) { page.at_css("form[action='#{signup_removal_path(record)}']")["data-turbo-confirm"] }
      expect(confirm.call(signup)).to eq("Remove Victor Volunteer from this shift? They will be told the next time they open ShiftUp. " \
                                         "The first eligible person on the waiting list gets the place.")
      expect(confirm.call(waiting)).to eq("Remove Wendy Volunteer from the waiting list? They will be told the next time they open ShiftUp.")
    end

    it "offers no Remove buttons once the shift has started" do
      started = create(:signup, shift: create(:shift, :past, activity: shift.activity))
      sign_in organizer

      get shift_path(started.shift)

      expect(response.body).not_to include(signup_removal_path(started))
    end
  end
end
