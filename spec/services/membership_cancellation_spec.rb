require 'rails_helper'

RSpec.describe MembershipCancellation do
  let(:organization) { create(:organization, name: "Green Campus Society") }
  let(:activity) { create(:activity, organization: organization) }
  let(:membership) { create(:membership, organization: organization) }
  let(:user) { membership.user }

  def leave
    described_class.new(membership).call
  end

  it "removes the membership" do
    result = leave

    expect(result).to be_success
    expect(result.message).to eq("You left Green Campus Society.")
    expect(user.member_of?(organization)).to be false
  end

  it "cancels the volunteer's upcoming shifts and waiting list places in the organization" do
    confirmed = create(:signup, user: user, shift: create(:shift, activity: activity))
    waiting = create(:signup, :waitlisted, user: user, shift: create(:shift, activity: activity))

    result = leave

    expect([ confirmed.reload, waiting.reload ]).to all(be_cancelled)
    expect(result.message).to eq("You left Green Campus Society. Your 1 upcoming shift and 1 waiting list place there were cancelled.")
  end

  it "uses the singular for a single cancelled sign-up" do
    create(:signup, user: user, shift: create(:shift, activity: activity))

    expect(leave.message).to eq("You left Green Campus Society. Your 1 upcoming shift there was cancelled.")
  end

  it "promotes the next eligible volunteer into each confirmed place that opens" do
    shift = create(:shift, activity: activity, capacity: 1)
    create(:signup, user: user, shift: shift)
    next_in_line = create(:signup, :waitlisted, shift: shift)

    leave

    expect(next_in_line.reload).to be_confirmed
  end

  it "keeps past sign-ups and attendance records" do
    past = create(:signup, user: user, shift: create(:shift, :past, activity: activity))
    past.update!(attendance: :present)

    leave

    expect(past.reload).to be_confirmed.and be_attendance_present
  end

  it "leaves the volunteer's sign-ups in other organizations alone" do
    elsewhere = create(:signup, user: user)

    leave

    expect(elsewhere.reload).to be_confirmed
  end

  it "keeps the membership and explains when a new sign-up appears meanwhile" do
    late = create(:signup, user: user, shift: create(:shift, activity: activity))
    # A sign-up made from another tab between the cancellations and the removal:
    allow_any_instance_of(ShiftCancellation).to receive(:call)

    result = leave

    expect(result).not_to be_success
    expect(result.message).to eq("You still have upcoming shifts or waiting list places in this organization. Please try again")
    expect(user.member_of?(organization)).to be true
    expect(late.reload).to be_confirmed
  end
end
