# Grants a user a role inside one organization. Roles are per organization:
# the same user can organize one society and volunteer for another.
class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  enum :role, { volunteer: 0, organizer: 1 }, validate: true

  validates :user_id, uniqueness: { scope: :organization_id }

  # A confirmed place must never be silently dropped: MembershipCancellation cancels the
  # volunteer's upcoming sign-ups first (promoting the waiting list), and this guard
  # refuses to remove a membership that still has any.
  before_destroy :ensure_no_upcoming_signups_here

  # The user's confirmed and waitlisted sign-ups for upcoming shifts of this organization.
  def upcoming_signups
    user.signups.active.joins(shift: :activity).merge(Shift.upcoming)
        .where(activities: { organization_id: organization_id })
  end

  # For example "1 upcoming shift and 2 waiting list places", or nil when there are none.
  def upcoming_signups_summary
    counts = upcoming_signups.pluck(:status).tally
    parts = []
    parts << "#{counts['confirmed']} upcoming #{'shift'.pluralize(counts['confirmed'])}" if counts["confirmed"]
    parts << "#{counts['waitlisted']} waiting list #{'place'.pluralize(counts['waitlisted'])}" if counts["waitlisted"]
    parts.to_sentence.presence
  end

  private

  def ensure_no_upcoming_signups_here
    return unless upcoming_signups.exists?

    errors.add(:base, "You still have upcoming shifts or waiting list places in this organization. Please try again")
    throw :abort
  end
end
