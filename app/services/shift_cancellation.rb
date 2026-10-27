# Cancels a volunteer's sign-up for a shift (US2).
#
# Cancelling a confirmed place promotes the earliest eligible volunteer from the waiting list
# (ShiftPromotion). Cancelling a waiting list entry just removes it. A shift that has started
# can no longer be cancelled. The sign-up row is kept with status "cancelled" as a record.
class ShiftCancellation
  Result = Data.define(:signup, :promoted, :error) do
    def success? = error.nil?

    def message
      return error unless success?
      return "You left the waiting list." if promoted.nil?

      message = "Your sign-up was cancelled."
      message += " The next volunteer on the waiting list has been confirmed." if promoted.any?
      message
    end
  end

  def initialize(shift:, user:)
    @shift = shift
    @user = user
  end

  def call
    Shift.transaction do
      shift.lock!
      signup = shift.signups.active.find_by(user: user)

      if signup.nil?
        Result.new(signup: nil, promoted: nil, error: "You are not signed up for this shift.")
      elsif shift.started?
        Result.new(signup: signup, promoted: nil, error: "This shift has already started, so the sign-up can no longer be cancelled.")
      else
        was_confirmed = signup.confirmed?
        signup.cancelled!
        promoted = ShiftPromotion.new(shift).call if was_confirmed
        Result.new(signup: signup, promoted: promoted, error: nil)
      end
    end
  end

  private

  attr_reader :shift, :user
end
