require 'rails_helper'

RSpec.describe "Attendances", type: :request do
  let(:organization) { create(:organization) }
  let(:shift) { create(:shift, :past, activity: create(:activity, organization: organization)) }
  let(:signup) { create(:signup, shift: shift, user: create(:user, name: "Vera Volunteer")) }
  let(:organizer) { create(:membership, :organizer, organization: organization).user }

  describe "PATCH /signups/:signup_id/attendance" do
    it "lets an organizer record attendance" do
      sign_in organizer

      patch signup_attendance_path(signup), params: { attendance: "present" }

      expect(response).to redirect_to(shift_path(shift))
      expect(flash[:notice]).to eq("Attendance saved: Vera Volunteer was present.")
      expect(signup.reload).to be_attendance_present
    end

    it "lets an organizer clear attendance again" do
      signup.update!(attendance: :absent)
      sign_in organizer

      patch signup_attendance_path(signup), params: { attendance: "unmarked" }

      expect(flash[:notice]).to eq("Attendance cleared for Vera Volunteer.")
      expect(signup.reload).to be_attendance_unmarked
    end

    it "explains why attendance cannot be recorded before the shift starts" do
      future = create(:signup, shift: create(:shift, activity: shift.activity))
      sign_in organizer

      patch signup_attendance_path(future), params: { attendance: "present" }

      expect(flash[:alert]).to eq("Attendance can only be recorded once the shift has started")
      expect(future.reload).to be_attendance_unmarked
    end

    it "rejects an unknown value" do
      sign_in organizer

      patch signup_attendance_path(signup), params: { attendance: "late" }

      expect(flash[:alert]).to eq("Attendance is not included in the list")
    end

    it "denies volunteers, including the volunteer themselves" do
      sign_in signup.user

      patch signup_attendance_path(signup), params: { attendance: "present" }

      expect(flash[:alert]).to eq("Only this organization's organizers can record attendance.")
      expect(signup.reload).to be_attendance_unmarked
    end

    it "denies an organizer of another organization using a direct URL" do
      sign_in create(:membership, :organizer).user

      patch signup_attendance_path(signup), params: { attendance: "present" }

      expect(response).to redirect_to(root_path)
      expect(signup.reload).to be_attendance_unmarked
    end

    it "requires login" do
      patch signup_attendance_path(signup), params: { attendance: "present" }

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "the shift page" do
    it "shows organizers attendance controls once the shift has started" do
      signup
      sign_in organizer

      get shift_path(shift)

      expect(response.body).to include("Mark present", "0 present · 0 absent · 1 not recorded")
    end

    it "hides attendance controls before the shift starts" do
      future = create(:signup, shift: create(:shift, activity: shift.activity))
      sign_in organizer

      get shift_path(future.shift)

      expect(response.body).not_to include("Mark present")
      expect(response.body).to include("Attendance can be recorded once the shift starts.")
    end
  end
end
