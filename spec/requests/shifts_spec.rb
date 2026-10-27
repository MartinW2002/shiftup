require 'rails_helper'

RSpec.describe "Shifts", type: :request do
  let(:organization) { create(:organization) }
  let(:activity) { create(:activity, organization: organization) }
  let(:shift) { create(:shift, activity: activity, capacity: 3) }
  let(:organizer) { create(:membership, :organizer, organization: organization).user }
  let(:volunteer) { create(:membership, organization: organization, user: create(:user, name: "Vera Volunteer")).user }
  let(:other_organizer) { create(:membership, :organizer).user }
  let(:starts_at) { 3.days.from_now.change(hour: 9) }
  let(:valid_params) { { shift: { starts_at: starts_at.strftime("%Y-%m-%dT%H:%M"), ends_at: (starts_at + 2.hours).strftime("%Y-%m-%dT%H:%M"), capacity: 4 } } }

  describe "as an organizer of the organization" do
    before { sign_in organizer }

    it "adds a shift, reading the times as Hong Kong time" do
      expect { post activity_shifts_path(activity), params: valid_params }.to change(activity.shifts, :count).by(1)

      expect(response).to redirect_to(activity_path(activity))
      expect(Shift.last.starts_at).to eq(starts_at)
      expect(Shift.last.starts_at.time_zone.name).to eq("Hong Kong")
    end

    it "rejects a shift in the past" do
      post activity_shifts_path(activity), params: { shift: valid_params[:shift].merge(starts_at: 1.day.ago.strftime("%Y-%m-%dT%H:%M")) }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Starts at must be in the future")
    end

    it "rejects a capacity of zero" do
      post activity_shifts_path(activity), params: { shift: valid_params[:shift].merge(capacity: 0) }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Capacity must be greater than 0")
    end

    it "sees the confirmed volunteers and the waiting list in order" do
      shift.update!(capacity: 1)
      create(:signup, shift: shift, user: volunteer)
      first = create(:signup, :waitlisted, shift: shift, created_at: 2.minutes.ago).user
      second = create(:signup, :waitlisted, shift: shift, created_at: 1.minute.ago).user

      get shift_path(shift)

      page = Nokogiri::HTML(response.body)
      expect(page.css("#confirmed-volunteers li").map(&:text).join).to include("Vera Volunteer")
      expect(page.css("#waiting-list li").map { |li| li.css("span")[1].text }).to eq([ first.name, second.name ])
    end

    it "updates the capacity" do
      patch shift_path(shift), params: { shift: { capacity: 5 } }

      expect(response).to redirect_to(shift_path(shift))
      expect(shift.reload.capacity).to eq(5)
    end

    it "refuses a capacity below the confirmed volunteers" do
      create_list(:signup, 2, shift: shift)

      patch shift_path(shift), params: { shift: { capacity: 1 } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Capacity cannot be lower than the 2 volunteers already confirmed")
      expect(shift.reload.capacity).to eq(3)
    end

    it "deletes a shift without sign-ups" do
      delete shift_path(shift)

      expect(response).to redirect_to(activity_path(activity))
      expect(Shift.exists?(shift.id)).to be false
    end

    it "refuses to delete a shift with sign-ups" do
      create(:signup, shift: shift)

      delete shift_path(shift)

      expect(flash[:alert]).to eq("This shift cannot be deleted because volunteers have signed up")
      expect(Shift.exists?(shift.id)).to be true
    end
  end

  describe "as a volunteer of the organization" do
    before { sign_in volunteer }

    it "sees the shift and its places, but not who signed up" do
      create(:signup, shift: shift, user: create(:user, name: "Other Volunteer"))

      get shift_path(shift)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("2 of 3 places left")
      expect(response.body).not_to include("Other Volunteer", "Edit shift")
    end

    it "cannot add, update or delete shifts" do
      post activity_shifts_path(activity), params: valid_params
      patch shift_path(shift), params: { shift: { capacity: 99 } }
      delete shift_path(shift)

      expect(flash[:alert]).to eq("Only this organization's organizers can manage its shifts.")
      expect(activity.shifts).to contain_exactly(shift)
      expect(shift.reload.capacity).to eq(3)
    end
  end

  describe "as an organizer of another organization" do
    before { sign_in other_organizer }

    it "cannot see, add, edit, update or delete shifts through direct URLs" do
      get shift_path(shift)
      expect(flash[:alert]).to eq("Only members can see this organization's shifts. Join it from the organizations page.")

      get new_activity_shift_path(activity)
      post activity_shifts_path(activity), params: valid_params
      get edit_shift_path(shift)
      patch shift_path(shift), params: { shift: { capacity: 99 } }
      delete shift_path(shift)

      expect(response).to redirect_to(root_path)
      expect(activity.shifts).to contain_exactly(shift)
      expect(shift.reload.capacity).to eq(3)
    end
  end
end
