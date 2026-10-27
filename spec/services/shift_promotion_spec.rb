require 'rails_helper'

RSpec.describe ShiftPromotion do
  let(:starts_at) { 2.days.from_now.change(hour: 9) }
  let(:shift) { create(:shift, starts_at: starts_at, ends_at: starts_at + 2.hours, capacity: 1) }

  def promote
    Shift.transaction do
      shift.lock!
      described_class.new(shift).call
    end
  end

  def waiting(created_at:)
    create(:signup, :waitlisted, shift: shift, created_at: created_at)
  end

  it "does nothing while the shift is full" do
    create(:signup, shift: shift)
    waiter = waiting(created_at: 1.minute.ago)

    expect(promote).to be_empty
    expect(waiter.reload).to be_waitlisted
  end

  it "confirms the earliest volunteer on the waiting list when a place is free" do
    later = waiting(created_at: 1.minute.ago)
    earliest = waiting(created_at: 5.minutes.ago)

    expect(promote).to eq([ earliest ])
    expect(earliest.reload).to be_confirmed
    expect(later.reload).to be_waitlisted
  end

  it "fills every free place, in waiting list order" do
    shift.update!(capacity: 3)
    first = waiting(created_at: 3.minutes.ago)
    second = waiting(created_at: 2.minutes.ago)
    third = waiting(created_at: 1.minute.ago)
    create(:signup, shift: shift)

    expect(promote).to eq([ first, second ])
    expect(third.reload).to be_waitlisted
  end

  it "skips a volunteer with an overlapping confirmed shift, who keeps their place in line" do
    first = waiting(created_at: 5.minutes.ago)
    create(:signup, user: first.user, shift: create(:shift, starts_at: starts_at + 1.hour, ends_at: starts_at + 3.hours))
    second = waiting(created_at: 1.minute.ago)

    expect(promote).to eq([ second ])
    expect(first.reload).to be_waitlisted
    expect(first.waitlist_position).to eq(1)
  end

  it "does not count the volunteer's waiting list entries elsewhere as overlaps" do
    first = waiting(created_at: 5.minutes.ago)
    create(:signup, :waitlisted, user: first.user, shift: create(:shift, starts_at: starts_at, ends_at: starts_at + 2.hours))

    expect(promote).to eq([ first ])
  end

  it "leaves the place free when nobody waiting is eligible" do
    first = waiting(created_at: 5.minutes.ago)
    create(:signup, user: first.user, shift: create(:shift, starts_at: starts_at, ends_at: starts_at + 1.hour))

    expect(promote).to be_empty
    expect(shift.reload).not_to be_full
  end

  it "never fills a shift that has started" do
    started = create(:shift, :past)
    waiter = create(:signup, :waitlisted, shift: started)

    result = Shift.transaction { started.lock!; described_class.new(started).call }

    expect(result).to be_empty
    expect(waiter.reload).to be_waitlisted
  end
end
