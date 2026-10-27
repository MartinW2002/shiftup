require 'rails_helper'

RSpec.describe "Activities", type: :request do
  let(:organization) { create(:organization) }
  let(:activity) { create(:activity, organization: organization, title: "Lake Clean-up") }
  let(:organizer) { create(:membership, :organizer, organization: organization).user }
  let(:volunteer) { create(:membership, organization: organization).user }
  let(:other_organizer) { create(:membership, :organizer).user }
  let(:valid_params) { { activity: { title: "Recycling Drive", location: "University Station", description: "Sort donations." } } }

  describe "as an organizer of the organization" do
    before { sign_in organizer }

    it "creates an activity" do
      expect { post organization_activities_path(organization), params: valid_params }.to change(organization.activities, :count).by(1)

      expect(response).to redirect_to(activity_path(Activity.last))
      expect(Activity.last).to have_attributes(title: "Recycling Drive", location: "University Station")
    end

    it "re-renders the form with errors for an invalid activity" do
      post organization_activities_path(organization), params: { activity: { title: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Title can&#39;t be blank")
    end

    it "ignores an attempt to put the activity into another organization" do
      other = create(:organization)

      post organization_activities_path(organization), params: { activity: valid_params[:activity].merge(organization_id: other.id) }

      expect(Activity.last.organization).to eq(organization)
    end

    it "updates an activity" do
      patch activity_path(activity), params: { activity: { title: "Lake Clean-up (morning)" } }

      expect(response).to redirect_to(activity_path(activity))
      expect(activity.reload.title).to eq("Lake Clean-up (morning)")
    end

    it "re-renders the edit form with errors for an invalid update" do
      patch activity_path(activity), params: { activity: { title: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Title can&#39;t be blank")
      expect(activity.reload.title).to eq("Lake Clean-up")
    end

    it "deletes an activity without sign-ups" do
      delete activity_path(activity)

      expect(response).to redirect_to(organization_path(organization))
      expect(Activity.exists?(activity.id)).to be false
    end

    it "refuses to delete an activity with sign-ups and explains why" do
      create(:signup, shift: create(:shift, activity: activity))

      delete activity_path(activity)

      expect(response).to redirect_to(activity_path(activity))
      expect(flash[:alert]).to eq("This activity cannot be deleted because volunteers have signed up for its shifts")
      expect(Activity.exists?(activity.id)).to be true
    end
  end

  describe "as a volunteer of the organization" do
    before { sign_in volunteer }

    it "shows the activity with its shifts and the volunteer's status" do
      shift = create(:shift, activity: activity)
      create(:signup, shift: shift, user: volunteer)

      get activity_path(activity)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Lake Clean-up", shift.time_range_text, "Confirmed")
      expect(response.body).not_to include("Add shift", "Edit activity")
    end

    it "cannot create activities" do
      expect { post organization_activities_path(organization), params: valid_params }.not_to change(Activity, :count)

      expect(flash[:alert]).to eq("Only this organization's organizers can manage its activities.")
    end

    it "cannot open the new activity form" do
      get new_organization_activity_path(organization)

      expect(response).to redirect_to(root_path)
    end

    it "cannot update or delete activities" do
      patch activity_path(activity), params: { activity: { title: "Hacked" } }
      delete activity_path(activity)

      expect(activity.reload.title).to eq("Lake Clean-up")
    end
  end

  describe "as an organizer of another organization" do
    before { sign_in other_organizer }

    it "cannot see the activity" do
      get activity_path(activity)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Only members can see this organization's activities. Join it from the organizations page.")
    end

    it "cannot create, edit, update or delete activities through direct URLs" do
      post organization_activities_path(organization), params: valid_params
      get edit_activity_path(activity)
      patch activity_path(activity), params: { activity: { title: "Hacked" } }
      delete activity_path(activity)

      expect(organization.activities).to contain_exactly(activity)
      expect(activity.reload.title).to eq("Lake Clean-up")
    end
  end

  it "requires login" do
    get activity_path(activity)

    expect(response).to redirect_to(new_user_session_path)
  end
end
