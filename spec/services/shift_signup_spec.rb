require 'rails_helper'

RSpec.describe ShiftSignup do
  let(:organization) { create(:organization) }
  let(:activity) { create(:activity, organization: organization, title: "Lake Clean-up") }
  let(:starts_at) { 2.days.from_now.change(hour: 9) }
  let(:shift) { create(:shift, activity: activity, starts_at: starts_at, ends_at: starts_at + 2.hours, capacity: 2) }
  let(:user) { create(:user) }

  def sign_up(shift_to_join = shift, volunteer = user)
    described_class.new(shift: shift_to_join, user: volunteer).call
  end

  describe "with free capacity" do
    it "confirms the volunteer" do
      result = sign_up

      expect(result).to be_success
      expect(result.signup).to be_confirmed
      expect(result.message).to eq("You are signed up for this shift.")
    end

    it "confirms volunteers until the capacity is reached" do
      create(:signup, shift: shift)

      expect(sign_up.signup).to be_confirmed
      expect(shift.signups.confirmed.count).to eq(2)
    end

    it "does not count cancelled sign-ups against the capacity" do
      create_list(:signup, 2, :cancelled, shift: shift)

      expect(sign_up.signup).to be_confirmed
    end
  end

  describe "when the shift is full" do
    before { create_list(:signup, 2, shift: shift) }

    it "adds the volunteer to the waiting list and reports the position" do
      create(:signup, :waitlisted, shift: shift)

      result = sign_up

      expect(result).to be_success
      expect(result.signup).to be_waitlisted
      expect(result.message).to eq("This shift is full. You are number 2 on the waiting list.")
    end

    it "never confirms more volunteers than the capacity" do
      create_list(:user, 3).each { |volunteer| sign_up(shift, volunteer) }

      expect(shift.signups.confirmed.count).to eq(2)
      expect(shift.signups.waitlist_order.map(&:waitlist_position)).to eq([ 1, 2, 3 ])
    end
  end

  describe "refusals" do
    it "refuses a second sign-up for the same shift" do
      sign_up

      result = sign_up

      expect(result).not_to be_success
      expect(result.error).to eq("You are already signed up for this shift.")
      expect(shift.signups.count).to eq(1)
    end

    it "refuses joining the same waiting list twice and repeats the position" do
      create_list(:signup, 2, shift: shift)
      sign_up

      result = sign_up

      expect(result.error).to eq("You are already on the waiting list for this shift (number 1).")
      expect(shift.signups.waitlisted.count).to eq(1)
    end

    it "allows signing up again after cancelling" do
      create(:signup, :cancelled, shift: shift, user: user)

      expect(sign_up.signup).to be_confirmed
    end

    it "refuses a shift that has already started" do
      started = create(:shift, :past, activity: activity)

      result = sign_up(started)

      expect(result.error).to eq("This shift has already started.")
      expect(started.signups).to be_empty
    end

    describe "overlapping shifts" do
      let(:overlapping) { create(:shift, starts_at: starts_at + 1.hour, ends_at: starts_at + 3.hours) }

      it "refuses a shift that overlaps a confirmed shift, naming the clash" do
        create(:signup, shift: shift, user: user)

        result = sign_up(overlapping)

        expect(result.error).to eq("This shift overlaps your confirmed shift for Lake Clean-up (#{shift.time_range_text}).")
        expect(overlapping.signups).to be_empty
      end

      it "also refuses joining the waiting list of an overlapping shift" do
        create(:signup, shift: shift, user: user)
        create_list(:signup, overlapping.capacity, shift: overlapping)

        expect(sign_up(overlapping).error).to start_with("This shift overlaps your confirmed shift")
      end

      it "checks confirmed shifts in other organizations too" do
        create(:signup, shift: overlapping, user: user)

        expect(sign_up.error).to start_with("This shift overlaps your confirmed shift")
      end

      it "allows an overlapping shift when the volunteer is only waitlisted for the other one" do
        create(:signup, :waitlisted, shift: shift, user: user)

        expect(sign_up(overlapping)).to be_success
      end

      it "allows a shift that starts exactly when the confirmed one ends" do
        create(:signup, shift: shift, user: user)
        back_to_back = create(:shift, starts_at: shift.ends_at, ends_at: shift.ends_at + 2.hours)

        expect(sign_up(back_to_back)).to be_success
      end

      it "ignores cancelled shifts" do
        create(:signup, :cancelled, shift: shift, user: user)

        expect(sign_up(overlapping)).to be_success
      end
    end
  end

  describe "fairness to the waiting list" do
    it "confirms an eligible volunteer already waiting before a newcomer takes a free place" do
      create(:signup, shift: shift)
      waiting = create(:signup, :waitlisted, shift: shift)
      shift.update_column(:capacity, 2) # a place opened without a promotion having run

      result = sign_up

      expect(waiting.reload).to be_confirmed
      expect(result.signup).to be_waitlisted
      expect(result.message).to eq("This shift is full. You are number 1 on the waiting list.")
    end

    it "gives the free place to the newcomer when nobody waiting is eligible" do
      blocked = create(:signup, :waitlisted, shift: shift)
      create(:signup, user: blocked.user, shift: create(:shift, starts_at: shift.starts_at, ends_at: shift.ends_at))

      expect(sign_up.signup).to be_confirmed
      expect(blocked.reload).to be_waitlisted
    end
  end

  # Each request runs in its own thread and database connection, so these examples
  # cannot use the usual per-example transaction.
  describe "under concurrent requests" do
    self.use_transactional_tests = false
    after { DatabaseCleaner.clean_with(:deletion) }

    # Pause between the capacity check and the insert. Without row locks, every request
    # would read the same free places during the pause and all of them would be confirmed.
    before do
      allow_any_instance_of(Shift).to receive(:full?).and_wrap_original do |original, *args|
        original.call(*args).tap { sleep 0.2 }
      end
    end

    # Thread#value re-raises any error (such as a deadlock) in the main thread.
    def in_parallel(jobs)
      jobs.map { |job| Thread.new { ActiveRecord::Base.connection_pool.with_connection { job.call } } }.each(&:value)
    end

    it "never confirms more volunteers than the capacity" do
      full_soon = create(:shift, capacity: 1)
      volunteers = create_list(:user, 4)

      in_parallel(volunteers.map { |volunteer| -> { sign_up(Shift.find(full_soon.id), User.find(volunteer.id)) } })

      expect(full_soon.signups.confirmed.count).to eq(1)
      expect(full_soon.signups.waitlisted.count).to eq(3)
    end

    it "never confirms one volunteer for two overlapping shifts" do
      first = create(:shift, starts_at: starts_at, ends_at: starts_at + 2.hours)
      second = create(:shift, starts_at: starts_at + 1.hour, ends_at: starts_at + 3.hours)

      in_parallel([ first, second ].map { |target| -> { sign_up(Shift.find(target.id), User.find(user.id)) } })

      expect(Signup.where(user: user).confirmed.count).to eq(1)
    end

    it "never exceeds the capacity when a cancellation and new sign-ups happen at once" do
      busy = create(:shift, capacity: 1)
      leaving = create(:signup, shift: busy).user
      waiting = create(:signup, :waitlisted, shift: busy, created_at: 1.minute.ago)
      newcomers = create_list(:user, 2)

      in_parallel(
        [ -> { ShiftCancellation.new(shift: Shift.find(busy.id), user: User.find(leaving.id)).call } ] +
        newcomers.map { |newcomer| -> { sign_up(Shift.find(busy.id), User.find(newcomer.id)) } }
      )

      expect(busy.signups.confirmed.count).to eq(1)
      expect(waiting.reload).to be_confirmed
    end

    it "does not deadlock when two cancellations promote the same volunteers in opposite order" do
      first = create(:shift, capacity: 1, starts_at: starts_at, ends_at: starts_at + 1.hour)
      second = create(:shift, capacity: 1, starts_at: starts_at + 2.hours, ends_at: starts_at + 3.hours)
      leavers = [ create(:signup, shift: first).user, create(:signup, shift: second).user ]
      wendy, victor = create_list(:user, 2)
      create(:signup, :waitlisted, shift: first, user: wendy, created_at: 2.minutes.ago)
      create(:signup, :waitlisted, shift: first, user: victor, created_at: 1.minute.ago)
      create(:signup, :waitlisted, shift: second, user: victor, created_at: 2.minutes.ago)
      create(:signup, :waitlisted, shift: second, user: wendy, created_at: 1.minute.ago)

      expect {
        in_parallel([ first, second ].zip(leavers).map { |target, leaver|
          -> { ShiftCancellation.new(shift: Shift.find(target.id), user: User.find(leaver.id)).call }
        })
      }.not_to raise_error

      expect(first.signups.confirmed.sole.user).to eq(wendy)
      expect(second.signups.confirmed.sole.user).to eq(victor)
    end
  end
end
