# An organizer removes a volunteer from a shift or its waiting list.
#
# Works like a cancellation (ShiftCancellation): the sign-up is kept with status "cancelled",
# and a freed confirmed place goes to the next eligible volunteer (ShiftPromotion). removed_at
# lets the volunteer be told on their next visit (SignupNotices). Only possible before the shift
# starts; afterwards organizers record attendance instead.
class ShiftRemoval
  Result = Data.define(:signup, :was_confirmed, :promoted, :error) do
    def success? = error.nil?
  end

  def initialize(signup)
    @signup = signup
  end

  def call
    shift = signup.shift
    Shift.transaction do
      shift.lock!
      signup.reload

      if signup.cancelled?
        failure("#{signup.user.name} is no longer signed up for this shift.")
      elsif shift.started?
        failure("This shift has already started, so nobody can be removed. Record attendance instead.")
      else
        was_confirmed = signup.confirmed?
        signup.update!(status: :cancelled, removed_at: Time.current)
        promoted = was_confirmed ? ShiftPromotion.new(shift).call : []
        Result.new(signup: signup, was_confirmed: was_confirmed, promoted: promoted, error: nil)
      end
    end
  end

  private

  attr_reader :signup

  def failure(error)
    Result.new(signup: signup, was_confirmed: nil, promoted: [], error: error)
  end
end
