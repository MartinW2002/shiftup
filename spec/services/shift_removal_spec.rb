require 'rails_helper'

RSpec.describe ShiftRemoval do
  let(:shift) { create(:shift, capacity: 1) }

  def remove(signup)
    described_class.new(signup).call
  end

  it "cancels a confirmed volunteer's place, records the removal and promotes the next in line" do
    removed = create(:signup, shift: shift)
    next_in_line = create(:signup, :waitlisted, shift: shift)

    freeze_time do
      result = remove(removed)

      expect(result).to be_success
      expect(result.was_confirmed).to be true
      expect(result.promoted).to eq([ next_in_line ])
      expect(removed.reload).to have_attributes(status: "cancelled", removed_at: Time.current, removal_notified_at: nil)
      expect(next_in_line.reload).to be_confirmed
    end
  end

  it "removes someone from the waiting list without promoting anyone" do
    create(:signup, shift: shift)
    waiting = create(:signup, :waitlisted, shift: shift)
    other = create(:signup, :waitlisted, shift: shift)

    result = remove(waiting)

    expect(result.was_confirmed).to be false
    expect(result.promoted).to be_empty
    expect(waiting.reload).to be_cancelled
    expect(other.reload).to be_waitlisted
  end

  it "refuses a sign-up that has been cancelled meanwhile" do
    signup = create(:signup, shift: shift)
    Signup.find(signup.id).cancelled!

    result = remove(signup)

    expect(result.error).to eq("#{signup.user.name} is no longer signed up for this shift.")
    expect(signup.reload.removed_at).to be_nil
  end

  it "refuses once the shift has started" do
    signup = create(:signup, shift: create(:shift, :past))

    expect(remove(signup).error).to eq("This shift has already started, so nobody can be removed. Record attendance instead.")
    expect(signup.reload).to be_confirmed
  end

  it "lets the volunteer sign up again afterwards" do
    signup = create(:signup, shift: shift)
    remove(signup)

    expect(ShiftSignup.new(shift: shift, user: signup.user).call).to be_success
  end
end
