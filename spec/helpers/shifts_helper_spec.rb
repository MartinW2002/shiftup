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

  describe "#delete_shift_confirmation" do
    let(:shift) { create(:shift, capacity: 3) }

    it "is a plain question when nobody is signed up" do
      create(:signup, :cancelled, shift: shift)

      expect(helper.delete_shift_confirmation(shift)).to eq("Delete this shift?")
    end

    it "names the confirmed volunteers and the people waiting, in singular and plural" do
      create(:signup, shift: shift)
      expect(helper.delete_shift_confirmation(shift)).to eq("Delete this shift? 1 confirmed volunteer will lose their place.")

      create(:signup, shift: shift)
      create_list(:signup, 2, :waitlisted, shift: shift)
      expect(helper.delete_shift_confirmation(shift)).to eq(
        "Delete this shift? 2 confirmed volunteers and 2 people on the waiting list will lose their place."
      )
    end

    it "only mentions the waiting list when nobody is confirmed" do
      create(:signup, :waitlisted, shift: shift)

      expect(helper.delete_shift_confirmation(shift)).to eq("Delete this shift? 1 person on the waiting list will lose their place.")
    end

    it "warns about attendance records for a shift that has already started" do
      past = create(:shift, :past)
      create_list(:signup, 3, shift: past)

      expect(helper.delete_shift_confirmation(past)).to eq("Delete this shift? Its attendance records for 3 volunteers will be deleted.")
    end

    it "is a plain question for a past shift nobody attended" do
      expect(helper.delete_shift_confirmation(create(:shift, :past))).to eq("Delete this shift?")
    end
  end
end
