require 'rails_helper'

RSpec.describe User, type: :model do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_length_of(:name).is_at_most(100) }
  it { is_expected.to have_many(:memberships).dependent(:destroy) }

  describe "roles per organization" do
    let(:user) { create(:user) }
    let(:society) { create(:organization) }
    let(:other_society) { create(:organization) }

    before { create(:membership, :organizer, user: user, organization: society) }

    it "is an organizer only of the organization that granted the role" do
      expect(user.organizer_of?(society)).to be true
      expect(user.organizer_of?(other_society)).to be false
    end

    it "is not a member of an organization without a membership" do
      expect(user.member_of?(other_society)).to be false
    end
  end
end
