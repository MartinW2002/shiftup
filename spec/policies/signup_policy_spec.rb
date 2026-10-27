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

  it "lets volunteers cancel only their own sign-ups" do
    signup = create(:signup, shift: shift)

    expect(described_class.new(signup.user, signup)).to permit_action(:destroy)
    expect(described_class.new(create(:membership, :organizer, organization: organization).user, signup)).to forbid_action(:destroy)
  end

  it "lets only the organization's organizers record attendance" do
    signup = create(:signup, shift: shift)
    organizer = create(:membership, :organizer, organization: organization).user
    volunteer = create(:membership, organization: organization).user
    other_organizer = create(:membership, :organizer).user

    expect(described_class.new(organizer, signup)).to permit_action(:mark_attendance)
    expect(described_class.new(volunteer, signup)).to forbid_action(:mark_attendance)
    expect(described_class.new(signup.user, signup)).to forbid_action(:mark_attendance)
    expect(described_class.new(other_organizer, signup)).to forbid_action(:mark_attendance)
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
