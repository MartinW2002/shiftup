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
end
