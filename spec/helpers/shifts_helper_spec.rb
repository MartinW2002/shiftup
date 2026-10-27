require 'rails_helper'

RSpec.describe ShiftsHelper, type: :helper do
  describe "#attendance_badge" do
    it "labels each attendance state" do
      expect(helper.attendance_badge(Signup.new(attendance: :present))).to include("Present", "badge-confirmed")
      expect(helper.attendance_badge(Signup.new(attendance: :absent))).to include("Absent", "badge-absent")
      expect(helper.attendance_badge(Signup.new(attendance: :unmarked))).to include("Not recorded")
    end
  end

  describe "#attendance_summary" do
    it "counts each attendance state" do
      signups = %i[present present absent unmarked].map { |attendance| Signup.new(attendance: attendance) }

      expect(helper.attendance_summary(signups)).to eq("2 present · 1 absent · 1 not recorded")
    end
  end

  describe "#places_text" do
    it "describes free places, or how many people wait for a full shift" do
      shift = create(:shift, capacity: 1)
      expect(helper.places_text(shift)).to eq("1 of 1 places left")

      create(:signup, shift: shift)
      create(:signup, :waitlisted, shift: shift)
      expect(helper.places_text(shift)).to eq("Full · 1 person waiting")
    end

    it "says when a shift is in progress or has ended" do
      expect(helper.places_text(build(:shift, starts_at: 1.hour.ago, ends_at: 1.hour.from_now))).to eq("In progress")
      expect(helper.places_text(build(:shift, starts_at: 3.hours.ago, ends_at: 1.hour.ago))).to eq("Ended")
    end
  end
end
