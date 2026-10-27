require 'rails_helper'

RSpec.describe ActivityPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:activity) { create(:activity, organization: organization) }

  def policy_for(user)
    described_class.new(user, activity)
  end

  it "lets the organization's organizers manage its activities" do
    organizer = create(:membership, :organizer, organization: organization).user

    expect(policy_for(organizer)).to permit_actions(%i[show new create edit update destroy])
  end

  it "lets volunteers see but not manage activities" do
    volunteer = create(:membership, organization: organization).user

    expect(policy_for(volunteer)).to permit_action(:show)
    expect(policy_for(volunteer)).to forbid_actions(%i[new create edit update destroy])
  end

  it "gives an organizer of another organization no access" do
    outsider = create(:membership, :organizer).user

    expect(policy_for(outsider)).to forbid_all_actions
  end

  it "gives visitors no access" do
    expect(policy_for(nil)).to forbid_all_actions
  end
end
