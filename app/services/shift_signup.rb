# Signs a volunteer up for a shift (US1).
#
# - Confirms the volunteer while the shift has free places, otherwise adds them to the waiting list.
# - Refuses a shift that has started, a second sign-up for the same shift, and a shift that
#   overlaps one of the volunteer's confirmed shifts (in any organization).
# - Places owed to the waiting list are filled first (ShiftPromotion), so a newcomer can never
#   take a free place ahead of an eligible volunteer who is already waiting.
#
# Concurrency: the shift row and then the users involved are locked (SELECT ... FOR UPDATE) for the
# whole check-and-insert, so simultaneous requests for the same shift, or by the same volunteer,
# run one after another. See ShiftPromotion for the lock order that prevents deadlocks.
class ShiftSignup
  Result = Data.define(:signup, :error) do
    def success? = error.nil?

    def message
      return error unless success?

      if signup.confirmed?
        "You are signed up for this shift."
      else
        "This shift is full. You are number #{signup.waitlist_position} on the waiting list."
      end
    end
  end

  def initialize(shift:, user:)
    @shift = shift
    @user = user
  end

  def call
    Shift.transaction do
      shift.lock!
      ShiftPromotion.new(shift).call(also_lock: [ user.id ])

      error = refusal_reason
      if error
        Result.new(signup: nil, error: error)
      else
        status = shift.full? ? :waitlisted : :confirmed
        Result.new(signup: shift.signups.create!(user: user, status: status), error: nil)
      end
    end
  end

  private

  attr_reader :shift, :user

  def refusal_reason
    if shift.started?
      "This shift has already started."
    elsif (existing = shift.signups.active.find_by(user: user))
      already_signed_up_message(existing)
    elsif (clash = overlapping_confirmed_shift)
      "This shift overlaps your confirmed shift for #{clash.activity.title} (#{clash.time_range_text})."
    end
  end

  def already_signed_up_message(signup)
    if signup.confirmed?
      "You are already signed up for this shift."
    else
      "You are already on the waiting list for this shift (number #{signup.waitlist_position})."
    end
  end

  def overlapping_confirmed_shift
    user.confirmed_shifts.overlapping(shift.starts_at, shift.ends_at).where.not(id: shift.id).includes(:activity).first
  end
end
