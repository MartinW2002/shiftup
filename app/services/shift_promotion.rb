# Fills a shift's free places from its waiting list (US2).
#
# Waiting volunteers are considered first come, first served (Signup.waitlist_order). A volunteer
# who now holds a confirmed shift overlapping this one is skipped and keeps their place in line;
# the next eligible volunteer is confirmed instead. Started shifts are never filled.
#
# Locking: the caller must hold the shift's row lock. This class then locks the waiting volunteers
# (plus any users passed in +also_lock+) in ascending id order. Every service that changes sign-ups
# locks one shift first and then users in ascending id order, so concurrent requests can wait for
# each other but never deadlock.
class ShiftPromotion
  def initialize(shift)
    @shift = shift
  end

  # Returns the sign-ups that were confirmed.
  def call(also_lock: [])
    waiting = shift.signups.waitlist_order.includes(:user).to_a
    lock_users(waiting.map(&:user_id) + also_lock)
    return [] if shift.started?

    promoted = []
    waiting.each do |signup|
      break if shift.full?
      next if overlaps_confirmed_shift?(signup.user)

      signup.confirmed!
      promoted << signup
    end
    promoted
  end

  private

  attr_reader :shift

  def lock_users(ids)
    User.where(id: ids.uniq).order(:id).lock.load
  end

  def overlaps_confirmed_shift?(user)
    user.confirmed_shifts.overlapping(shift.starts_at, shift.ends_at).where.not(id: shift.id).exists?
  end
end
