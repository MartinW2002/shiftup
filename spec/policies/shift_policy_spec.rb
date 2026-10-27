require 'rails_helper'

RSpec.describe ShiftPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:shift) { create(:shift, activity: create(:activity, organization: organization)) }

  def policy_for(user)
    described_class.new(user, shift)
  end

  it "lets the organization's organizers manage its shifts" do
    organizer = create(:membership, :organizer, organization: organization).user

    expect(policy_for(organizer)).to permit_actions(%i[show new create edit update destroy])
  end

  it "lets volunteers see but not manage shifts" do
    volunteer = create(:membership, organization: organization).user

    expect(policy_for(volunteer)).to permit_action(:show)
    expect(policy_for(volunteer)).to forbid_actions(%i[new create edit update destroy])
  end

  it "gives an organizer of another organization no access" do
    expect(policy_for(create(:membership, :organizer).user)).to forbid_all_actions
  end

  describe "scope" do
    it "returns the shifts of the user's organizations only" do
      volunteer = create(:membership, organization: organization).user
      create(:shift)

      expect(Pundit.policy_scope!(volunteer, Shift)).to contain_exactly(shift)
    end

    it "returns nothing to visitors" do
      shift

      expect(Pundit.policy_scope!(nil, Shift)).to be_empty
    end
  end
end
