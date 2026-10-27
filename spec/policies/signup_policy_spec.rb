require 'rails_helper'

RSpec.describe SignupPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:shift) { create(:shift, activity: create(:activity, organization: organization)) }

  it "lets members of the shift's organization sign up" do
    %i[volunteer organizer].each do |role|
      member = create(:membership, organization: organization, role: role).user

      expect(described_class.new(member, Signup.new(shift: shift, user: member))).to permit_action(:create)
    end
  end

  it "refuses non-members" do
    outsider = create(:membership).user

    expect(described_class.new(outsider, Signup.new(shift: shift, user: outsider))).to forbid_action(:create)
  end

  describe "scope" do
    it "returns only the user's own sign-ups" do
      mine = create(:signup)
      create(:signup, shift: mine.shift)

      expect(Pundit.policy_scope!(mine.user, Signup)).to contain_exactly(mine)
    end

    it "returns nothing to visitors" do
      create(:signup)

      expect(Pundit.policy_scope!(nil, Signup)).to be_empty
    end
  end
end
