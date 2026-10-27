require 'rails_helper'

RSpec.describe Signup, type: :model do
  it { is_expected.to define_enum_for(:status).with_values(confirmed: 0, waitlisted: 1, cancelled: 2).validating }
  it { is_expected.to define_enum_for(:attendance).with_values(unmarked: 0, present: 1, absent: 2).with_prefix.validating }

  it "starts confirmed with attendance unmarked" do
    expect(described_class.new).to have_attributes(status: "confirmed", attendance: "unmarked")
  end

  it "counts only confirmed and waitlisted sign-ups as active" do
    shift = create(:shift)
    confirmed = create(:signup, shift: shift)
    waitlisted = create(:signup, :waitlisted, shift: shift)
    create(:signup, :cancelled, shift: shift)

    expect(shift.signups.active).to contain_exactly(confirmed, waitlisted)
  end

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

  describe "#waitlist_position" do
    let(:shift) { create(:shift) }

    it "counts the volunteers who joined the waiting list earlier" do
      first = create(:signup, :waitlisted, shift: shift, created_at: 3.minutes.ago)
      second = create(:signup, :waitlisted, shift: shift, created_at: 2.minutes.ago)
      create(:signup, :waitlisted, created_at: 5.minutes.ago) # another shift's waiting list

      expect([ first.waitlist_position, second.waitlist_position ]).to eq([ 1, 2 ])
    end

    it "breaks a tie in join time by sign-up order" do
      joined_at = 1.minute.ago
      first = create(:signup, :waitlisted, shift: shift, created_at: joined_at)
      second = create(:signup, :waitlisted, shift: shift, created_at: joined_at)

      expect([ first.waitlist_position, second.waitlist_position ]).to eq([ 1, 2 ])
    end

    it "is nil for a confirmed sign-up" do
      expect(create(:signup, shift: shift).waitlist_position).to be_nil
    end
  end

  describe "attendance" do
    let(:started) { create(:shift, :past) }

    it "can be recorded for a confirmed volunteer once the shift has started" do
      signup = create(:signup, shift: started)

      expect(signup.update(attendance: :present)).to be true
      expect(signup.update(attendance: :absent)).to be true
      expect(signup.update(attendance: :unmarked)).to be true
    end

    it "cannot be recorded before the shift starts" do
      signup = create(:signup)

      expect(signup.update(attendance: :present)).to be false
      expect(signup.errors[:attendance]).to include("can only be recorded once the shift has started")
    end

    it "cannot be recorded for a volunteer who was only on the waiting list" do
      signup = create(:signup, :waitlisted, shift: started)

      expect(signup.update(attendance: :present)).to be false
      expect(signup.errors[:attendance]).to include("can only be recorded for confirmed volunteers")
    end

    it "rejects an unknown value" do
      signup = create(:signup, shift: started)

      expect(signup.update(attendance: "late")).to be false
      expect(signup.errors[:attendance]).to include("is not included in the list")
    end
  end
end
