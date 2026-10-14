require 'rails_helper'

RSpec.describe OrganizationPolicy, type: :policy do
  let(:organization) { create(:organization) }

  context "for an organizer of the organization" do
    subject { described_class.new(create(:membership, :organizer, organization: organization).user, organization) }

    it { is_expected.to permit_actions(%i[show update]) }
  end

  context "for a volunteer of the organization" do
    subject { described_class.new(create(:membership, organization: organization).user, organization) }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_action(:update) }
  end

  context "for an organizer of another organization" do
    subject { described_class.new(create(:membership, :organizer).user, organization) }

    it { is_expected.to forbid_actions(%i[show update]) }
  end

  describe "scope" do
    it "returns only the user's own organizations" do
      user = create(:membership, organization: organization).user
      create(:organization)

      expect(Pundit.policy_scope!(user, Organization)).to contain_exactly(organization)
    end
  end
end
