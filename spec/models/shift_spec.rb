require 'rails_helper'

RSpec.describe Shift, type: :model do
  it { is_expected.to validate_presence_of(:capacity) }
  it { is_expected.to validate_numericality_of(:capacity).only_integer.is_greater_than(0) }

  it "is invalid when it ends before it starts" do
    shift = build(:shift, starts_at: 1.day.from_now, ends_at: 1.day.from_now - 1.hour)

    expect(shift).not_to be_valid
    expect(shift.errors[:ends_at]).to include("must be after the start time")
  end

  describe "#overlaps?" do
    let(:shift) { build(:shift, starts_at: Time.zone.parse("2026-11-07 10:00"), ends_at: Time.zone.parse("2026-11-07 12:00")) }

    it "is true for a shift that starts during it" do
      other = build(:shift, starts_at: Time.zone.parse("2026-11-07 11:00"), ends_at: Time.zone.parse("2026-11-07 13:00"))
      expect(shift.overlaps?(other)).to be true
    end

    it "is false for a shift that starts exactly when it ends" do
      other = build(:shift, starts_at: Time.zone.parse("2026-11-07 12:00"), ends_at: Time.zone.parse("2026-11-07 14:00"))
      expect(shift.overlaps?(other)).to be false
    end
  end

  describe ".overlapping" do
    it "finds shifts that share any time with the given range" do
      day = 7.days.from_now.beginning_of_day
      morning = create(:shift, starts_at: day.change(hour: 9), ends_at: day.change(hour: 11))
      create(:shift, starts_at: day.change(hour: 11), ends_at: day.change(hour: 13))
      create(:shift, starts_at: day.change(hour: 7), ends_at: day.change(hour: 9))

      expect(Shift.overlapping(day.change(hour: 10), day.change(hour: 11))).to contain_exactly(morning)
    end
  end

  describe ".upcoming" do
    it "returns future shifts, soonest first" do
      later = create(:shift, starts_at: 3.days.from_now)
      sooner = create(:shift, starts_at: 1.day.from_now)
      create(:shift, :past)

      expect(Shift.upcoming).to eq([ sooner, later ])
    end
  end

  describe "database constraints" do
    let(:shift) { create(:shift) }

    it "rejects a capacity of zero even when validations are skipped" do
      expect { shift.update_column(:capacity, 0) }.to raise_error(ActiveRecord::StatementInvalid, /shifts_capacity_positive/)
    end

    it "rejects an end time before the start even when validations are skipped" do
      expect { shift.update_column(:ends_at, shift.starts_at - 1.hour) }.to raise_error(ActiveRecord::StatementInvalid, /shifts_ends_after_start/)
    end
  end

  it "must start in the future when created" do
    shift = build(:shift, starts_at: 1.hour.ago, ends_at: 1.hour.from_now)

    expect(shift).not_to be_valid
    expect(shift.errors[:starts_at]).to include("must be in the future")
  end

  describe "places" do
    let(:shift) { create(:shift, capacity: 2) }

    it "counts only confirmed sign-ups against the capacity" do
      create(:signup, shift: shift)
      create(:signup, :waitlisted, shift: shift)
      create(:signup, :cancelled, shift: shift)

      expect(shift).to have_attributes(confirmed_count: 1, places_left: 1, full?: false, waitlist_count: 1)
    end

    it "is full when confirmed sign-ups reach the capacity" do
      create_list(:signup, 2, shift: shift)

      expect(shift).to have_attributes(places_left: 0, full?: true)
    end
  end

  describe "editing" do
    let(:shift) { create(:shift, capacity: 3) }

    it "cannot lower the capacity below the confirmed volunteers" do
      create_list(:signup, 2, shift: shift)

      expect(shift.update(capacity: 1)).to be false
      expect(shift.errors[:capacity]).to include("cannot be lower than the 2 volunteers already confirmed")
      expect(shift.update(capacity: 2)).to be true
    end

    it "cannot move the times once volunteers have signed up" do
      create(:signup, :waitlisted, shift: shift)

      expect(shift.update(ends_at: shift.ends_at + 1.hour)).to be false
      expect(shift.errors[:base]).to include("Times cannot be changed after volunteers have signed up")
    end

    it "can move the times while nobody is signed up" do
      create(:signup, :cancelled, shift: shift)

      expect(shift.update(ends_at: shift.ends_at + 1.hour)).to be true
    end
  end

  describe "deleting" do
    let(:shift) { create(:shift) }

    it "is refused while volunteers are signed up" do
      signup = create(:signup, shift: shift)

      expect(shift.destroy).to be false
      expect(shift.errors[:base]).to include("This shift cannot be deleted because volunteers have signed up")
      expect(signup.reload).to be_persisted
    end

    it "removes cancelled sign-ups with the shift" do
      create(:signup, :cancelled, shift: shift)

      expect { shift.destroy }.to change(Signup, :count).by(-1)
      expect(shift).to be_destroyed
    end
  end

  describe "#time_range_text" do
    it "shows the end time only when the shift ends on the same day" do
      shift = build(:shift, starts_at: Time.zone.parse("2026-11-07 09:00"), ends_at: Time.zone.parse("2026-11-07 11:30"))

      expect(shift.time_range_text).to eq("Sat 7 Nov 2026, 09:00–11:30")
    end

    it "shows both dates for a shift that ends on another day" do
      shift = build(:shift, starts_at: Time.zone.parse("2026-11-07 22:00"), ends_at: Time.zone.parse("2026-11-08 02:00"))

      expect(shift.time_range_text).to eq("Sat 7 Nov 2026, 22:00–Sun 8 Nov 2026, 02:00")
    end
  end
end
