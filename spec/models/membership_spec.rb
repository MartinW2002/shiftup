require 'rails_helper'

RSpec.describe Membership, type: :model do
  subject { build(:membership) }

  it { is_expected.to define_enum_for(:role).with_values(volunteer: 0, organizer: 1).validating }
  it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:organization_id) }

  it "defaults to the volunteer role" do
    expect(described_class.new.role).to eq("volunteer")
  end

  it "rejects an unknown role with a validation error" do
    membership = build(:membership, role: "admin")

    expect(membership).not_to be_valid
    expect(membership.errors[:role]).to be_present
  end

  it "lets the same user hold different roles in different organizations" do
    user = create(:user)
    create(:membership, :organizer, user: user)

    expect(build(:membership, user: user)).to be_valid
  end
end
