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

  describe "leaving (destroying the membership)" do
    let(:organization) { create(:organization) }
    let(:membership) { create(:membership, organization: organization) }
    let(:activity) { create(:activity, organization: organization) }

    it "is allowed without upcoming sign-ups in the organization" do
      expect(membership.destroy).to be_truthy
      expect(Membership.exists?(membership.id)).to be false
    end

    # MembershipCancellation cancels these first; the guard stops anything else from dropping them.
    it "is refused while the volunteer is confirmed for an upcoming shift there" do
      create(:signup, user: membership.user, shift: create(:shift, activity: activity))

      expect(membership.destroy).to be false
      expect(membership.errors[:base]).to include("You still have upcoming shifts or waiting list places in this organization. Please try again")
    end

    it "is refused while the volunteer is on an upcoming waiting list there" do
      create(:signup, :waitlisted, user: membership.user, shift: create(:shift, activity: activity))

      expect(membership.destroy).to be false
    end

    it "ignores past and cancelled sign-ups, and sign-ups in other organizations" do
      create(:signup, user: membership.user, shift: create(:shift, :past, activity: activity))
      create(:signup, :cancelled, user: membership.user, shift: create(:shift, activity: activity))
      create(:signup, user: membership.user)

      expect(membership.destroy).to be_truthy
    end

    it "keeps the volunteer's past sign-ups and attendance" do
      past = create(:signup, user: membership.user, shift: create(:shift, :past, activity: activity))
      past.update!(attendance: :present)

      membership.destroy

      expect(past.reload).to be_attendance_present
    end
  end

  describe "#upcoming_signups_summary" do
    let(:membership) { create(:membership) }
    let(:activity) { create(:activity, organization: membership.organization) }

    def sign_up(status, count = 1)
      create_list(:signup, count, status, user: membership.user, shift: create(:shift, activity: activity))
    end

    it "is nil without upcoming sign-ups" do
      create(:signup, user: membership.user, shift: create(:shift, :past, activity: activity))

      expect(membership.upcoming_signups_summary).to be_nil
    end

    it "counts shifts and waiting list places, in singular and plural" do
      sign_up(:confirmed)
      expect(membership.upcoming_signups_summary).to eq("1 upcoming shift")

      sign_up(:waitlisted)
      sign_up(:waitlisted)
      expect(membership.upcoming_signups_summary).to eq("1 upcoming shift and 2 waiting list places")
    end

    it "ignores cancelled sign-ups and other organizations" do
      sign_up(:cancelled)
      create(:signup, user: membership.user)

      expect(membership.upcoming_signups_summary).to be_nil
    end
  end
end
