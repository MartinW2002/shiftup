require 'rails_helper'

RSpec.describe OrganizationPolicy, type: :policy do
  let(:organization) { create(:organization) }

  context "for an organizer of the organization" do
    subject { described_class.new(create(:membership, :organizer, organization: organization).user, organization) }

    it { is_expected.to permit_actions(%i[show update]) }
    it { is_expected.to forbid_action(:join) }
  end

  context "for a volunteer of the organization" do
    subject { described_class.new(create(:membership, organization: organization).user, organization) }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_actions(%i[update join]) }
  end

  context "for an organizer of another organization" do
    subject { described_class.new(create(:membership, :organizer).user, organization) }

    it { is_expected.to forbid_actions(%i[show update]) }
    it { is_expected.to permit_action(:join) }
  end

  context "for a visitor who is not logged in" do
    subject { described_class.new(nil, organization) }

    it { is_expected.to forbid_actions(%i[index show join update]) }
  end

  describe "scope" do
    it "lists every organization to a signed-in user so they can join one" do
      other = create(:organization)

      expect(Pundit.policy_scope!(create(:user), Organization)).to contain_exactly(organization, other)
    end

    it "lists nothing to a visitor" do
      organization

      expect(Pundit.policy_scope!(nil, Organization)).to be_empty
    end
  end
end
