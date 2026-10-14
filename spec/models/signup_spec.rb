require 'rails_helper'

RSpec.describe Signup, type: :model do
  it { is_expected.to define_enum_for(:status).with_values(confirmed: 0, waitlisted: 1, cancelled: 2).validating }

  describe ".waitlist_order" do
    it "orders waitlisted sign-ups by join time" do
      shift = create(:shift)
      later = create(:signup, :waitlisted, shift: shift, created_at: 1.minute.ago)
      earlier = create(:signup, :waitlisted, shift: shift, created_at: 5.minutes.ago)
      create(:signup, shift: shift)

      expect(shift.signups.waitlist_order).to eq([ earlier, later ])
    end
  end

  it "does not allow two active sign-ups for the same volunteer and shift" do
    existing = create(:signup)

    expect {
      create(:signup, :waitlisted, shift: existing.shift, user: existing.user)
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "allows signing up again after cancelling" do
    cancelled = create(:signup, :cancelled)

    expect(build(:signup, shift: cancelled.shift, user: cancelled.user).save).to be true
  end
end
