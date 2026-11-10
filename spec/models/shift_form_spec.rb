require 'rails_helper'

RSpec.describe ShiftForm, type: :model do
  let(:activity) { create(:activity) }
  let(:day) { 3.days.from_now.to_date }
  let(:attributes) { { date: day.iso8601, start_time: "09:00", end_time: "11:00", capacity: "4" } }

  def new_form(**overrides)
    described_class.new(shift: activity.shifts.build, **attributes, **overrides)
  end

  describe "adding a shift" do
    it "creates one shift from a date, a start time and an end time, in Hong Kong time" do
      form = new_form

      expect(form.save).to be true
      expect(form.shifts.sole).to have_attributes(starts_at: Time.zone.parse("#{day} 09:00"),
                                                   ends_at: Time.zone.parse("#{day} 11:00"), capacity: 4)
    end

    it "ends the next day when the end time is earlier than the start time" do
      form = new_form(start_time: "22:00", end_time: "02:00")

      expect(form).to be_overnight
      expect(form.save).to be true
      expect(form.shifts.sole.ends_at).to eq(Time.zone.parse("#{day + 1} 02:00"))
    end

    it "rejects an end time equal to the start time" do
      form = new_form(end_time: "09:00")

      expect(form.save).to be false
      expect(form.errors[:end_time]).to include("must be different from the start time")
    end

    it "requires every field" do
      form = described_class.new(shift: activity.shifts.build)

      expect(form.save).to be false
      expect(form.errors.attribute_names).to include(:date, :start_time, :end_time, :capacity)
    end

    it "rejects times that cannot be read" do
      form = new_form(start_time: "9am", end_time: "25:00")

      expect(form).not_to be_valid
      expect(form.errors[:start_time]).to include("must be a time like 09:00")
      expect(form.errors[:end_time]).to include("must be a time like 17:00")
    end

    it "rejects a date in the past" do
      form = new_form(date: Date.yesterday.iso8601)

      expect(form.save).to be false
      expect(form.errors[:date]).to include("must be today or later")
    end

    it "rejects a start time that has already passed today" do
      travel_to(Time.zone.parse("#{Date.current} 12:00")) do
        form = new_form(date: Date.current.iso8601, start_time: "08:00", end_time: "10:00")

        expect(form.save).to be false
        expect(form.errors[:start_time]).to include("must be later than now for a shift today")
      end
    end

    it "passes on the shift's own validations, such as the capacity" do
      form = new_form(capacity: "0")

      expect(form.save).to be false
      expect(form.errors.full_messages).to include("Capacity must be greater than 0")
    end
  end

  describe "repeating on more dates" do
    let(:repeat) { [ (day + 14).iso8601, (day + 7).iso8601, day.iso8601 ] }

    it "creates a shift on the main date and every picked date, once each and in order" do
      form = new_form(recurring: "1", repeat_dates: repeat)

      expect(form.save).to be true
      expect(form.shifts.map { |shift| shift.starts_at.to_date }).to eq([ day, day + 7, day + 14 ])
      expect(form.shifts).to all(have_attributes(capacity: 4))
    end

    it "keeps the same times on every date, also past midnight" do
      form = new_form(start_time: "22:00", end_time: "01:00", recurring: "1", repeat_dates: [ (day + 7).iso8601 ])

      form.save

      expect(form.shifts.map { |shift| [ shift.starts_at.hour, shift.ends_at.hour, (shift.ends_at.to_date - shift.starts_at.to_date).to_i ] })
        .to eq([ [ 22, 1, 1 ], [ 22, 1, 1 ] ])
    end

    it "ignores the picked dates when repeating is off" do
      form = new_form(recurring: "0", repeat_dates: repeat)

      expect(form.dates).to eq([ day ])
    end

    it "ignores dates that cannot be read" do
      expect(new_form(recurring: "1", repeat_dates: [ "not-a-date", "" ]).dates).to eq([ day ])
    end

    it "rejects picked dates in the past" do
      form = new_form(recurring: "1", repeat_dates: [ Date.yesterday.iso8601 ])

      expect(form.save).to be false
      expect(form.errors[:base]).to include("Repeat dates must be today or later")
    end

    it "limits how many dates can be added at once" do
      dates = (1..ShiftForm::MAX_DATES).map { |offset| (day + offset).iso8601 }

      form = new_form(recurring: "1", repeat_dates: dates)

      expect(form).not_to be_valid
      expect(form.errors[:base]).to include("A shift can be repeated on at most #{ShiftForm::MAX_DATES} dates at once")
    end

    it "creates no shift at all when one of the dates fails" do
      form = new_form(recurring: "1", repeat_dates: [ (day + 7).iso8601 ])
      allow_any_instance_of(Shift).to receive(:save).and_wrap_original do |original, *args|
        shift = original.receiver
        shift.starts_at.to_date == day + 7 ? (shift.errors.add(:base, "Simulated failure") && false) : original.call(*args)
      end

      expect { expect(form.save).to be false }.not_to change(Shift, :count)
      expect(form.errors[:base]).to include("Simulated failure")
    end
  end

  describe "editing a shift" do
    let(:shift) { create(:shift, activity: activity, starts_at: Time.zone.parse("#{day} 09:00"), ends_at: Time.zone.parse("#{day} 11:00"), capacity: 3) }

    it "fills the form from the shift" do
      form = described_class.new(shift: shift)

      expect(form).to have_attributes(date: day, start_time: "09:00", end_time: "11:00", capacity: 3)
      expect(form).to be_persisted
    end

    it "changes the shift" do
      form = described_class.new(shift: shift, start_time: "10:00", end_time: "01:00", capacity: "5")

      expect(form.save).to be true
      expect(shift.reload).to have_attributes(starts_at: Time.zone.parse("#{day} 10:00"),
                                              ends_at: Time.zone.parse("#{day + 1} 01:00"), capacity: 5)
    end

    it "never repeats an existing shift" do
      form = described_class.new(shift: shift, recurring: "1", repeat_dates: [ (day + 7).iso8601 ])

      expect(form.dates).to eq([ day ])
    end

    it "shows the shift's own refusals, such as moving times after sign-ups" do
      create(:signup, shift: shift)

      form = described_class.new(shift: shift, start_time: "10:00")

      expect(form.save).to be false
      expect(form.errors[:base]).to include("Times cannot be changed after volunteers have signed up")
    end

    it "shows a capacity below the confirmed volunteers on the capacity field" do
      create_list(:signup, 2, shift: shift)

      form = described_class.new(shift: shift, capacity: "1")

      expect(form.save).to be false
      expect(form.errors[:capacity]).to include("cannot be lower than the 2 volunteers already confirmed")
    end

    it "still allows changing the capacity of a shift that has started" do
      started = create(:shift, :past, activity: activity, capacity: 2)

      expect(described_class.new(shift: started, capacity: "3").save).to be true
    end

    it "rejects moving the start into the past" do
      form = described_class.new(shift: shift, date: Date.yesterday.iso8601)

      expect(form.save).to be false
      expect(form.errors[:date]).to include("must be today or later")
    end
  end
end
