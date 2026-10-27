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
      day = Time.zone.parse("2026-11-07")
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
      create(:shift, starts_at: 1.day.ago)

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
end
