require 'rails_helper'

RSpec.describe "Registrations", type: :request do
  let(:valid_params) do
    { user: { name: "Vera Volunteer", email: "vera@example.com", password: "password123", password_confirmation: "password123" } }
  end

  it "creates an account with a name" do
    expect { post user_registration_path, params: valid_params }.to change(User, :count).by(1)

    expect(User.last.name).to eq("Vera Volunteer")
  end

  it "rejects an account without a name" do
    valid_params[:user][:name] = ""

    expect { post user_registration_path, params: valid_params }.not_to change(User, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Name can&#39;t be blank")
  end

  it "never lets a user grant themselves a membership while signing up" do
    organization = create(:organization)
    valid_params[:user][:memberships_attributes] = [ { organization_id: organization.id, role: "organizer" } ]

    post user_registration_path, params: valid_params

    expect(Membership.count).to eq(0)
  end

  it "lets a user change their name" do
    user = create(:user, name: "Old Name")
    sign_in user

    put user_registration_path, params: { user: { name: "New Name", current_password: "password123" } }

    expect(user.reload.name).to eq("New Name")
  end

  it "does not offer a password reset, since the demo sends no email" do
    get new_user_session_path

    expect(response.body).not_to include("Forgot your password?")
  end

  describe "deleting the account" do
    let(:user) { create(:user) }

    before { sign_in user }

    it "deletes the account and signs the user out" do
      create(:signup, :cancelled, user: user)
      create(:signup, shift: create(:shift, :past), user: user)

      delete user_registration_path

      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq("Bye! Your account has been successfully cancelled. We hope to see you again soon.")
      expect(User.exists?(user.id)).to be false
    end

    it "is refused while the user has an upcoming shift, so the place can be passed on" do
      create(:signup, user: user)

      delete user_registration_path

      expect(response).to redirect_to(edit_user_registration_path)
      expect(flash[:alert]).to eq("Cancel your upcoming shifts and waiting list places before deleting your account")
      expect(User.exists?(user.id)).to be true
    end

    it "is refused while the user is on an upcoming waiting list" do
      create(:signup, :waitlisted, user: user)

      delete user_registration_path

      expect(User.exists?(user.id)).to be true
    end
  end
end
