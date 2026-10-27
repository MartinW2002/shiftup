require 'rails_helper'

RSpec.describe ShiftCancellation do
  let(:shift) { create(:shift, capacity: 1) }
  let(:user) { create(:user) }

  def cancel(target = shift)
    described_class.new(shift: target, user: user).call
  end

  it "cancels a confirmed sign-up and keeps it as a record" do
    signup = create(:signup, shift: shift, user: user)

    result = cancel

    expect(result).to be_success
    expect(result.message).to eq("Your sign-up was cancelled.")
    expect(signup.reload).to be_cancelled
  end

  it "confirms the first volunteer waiting when a confirmed place is cancelled" do
    create(:signup, shift: shift, user: user)
    first = create(:signup, :waitlisted, shift: shift, created_at: 2.minutes.ago)
    second = create(:signup, :waitlisted, shift: shift, created_at: 1.minute.ago)

    result = cancel

    expect(result.promoted).to eq([ first ])
    expect(result.message).to eq("Your sign-up was cancelled. The next volunteer on the waiting list has been confirmed.")
    expect(first.reload).to be_confirmed
    expect(second.reload.waitlist_position).to eq(1)
  end

  it "confirms the next eligible volunteer when the first in line has an overlap" do
    create(:signup, shift: shift, user: user)
    first = create(:signup, :waitlisted, shift: shift, created_at: 2.minutes.ago)
    second = create(:signup, :waitlisted, shift: shift, created_at: 1.minute.ago)
    create(:signup, user: first.user, shift: create(:shift, starts_at: shift.starts_at, ends_at: shift.ends_at))

    cancel

    expect(second.reload).to be_confirmed
    expect(first.reload).to be_waitlisted
  end

  it "removes a waiting list entry without promoting anyone" do
    create(:signup, shift: shift)
    signup = create(:signup, :waitlisted, shift: shift, user: user)
    other = create(:signup, :waitlisted, shift: shift)

    result = cancel

    expect(result.message).to eq("You left the waiting list.")
    expect(signup.reload).to be_cancelled
    expect(other.reload).to be_waitlisted
  end

  it "refuses when the volunteer is not signed up" do
    create(:signup, :cancelled, shift: shift, user: user)

    expect(cancel.error).to eq("You are not signed up for this shift.")
  end

  it "refuses once the shift has started" do
    started = create(:shift, :past)
    signup = create(:signup, shift: started, user: user)

    expect(cancel(started).error).to eq("This shift has already started, so the sign-up can no longer be cancelled.")
    expect(signup.reload).to be_confirmed
  end

  it "lets the volunteer sign up again afterwards" do
    create(:signup, shift: shift, user: user)
    cancel

    expect(ShiftSignup.new(shift: shift, user: user).call.signup).to be_confirmed
  end
end
