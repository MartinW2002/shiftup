# Search and filters for the "Find shifts" page. Always applied on top of the user's
# policy scope, so it only ever returns shifts of organizations the user belongs to.
class ShiftSearch
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :q, :string
  attribute :organization_id, :integer
  attribute :from, :date
  attribute :to, :date
  attribute :open_only, :boolean, default: false

  validate :to_not_before_from

  def results(scope)
    shifts = scope.joins(:activity).includes(activity: :organization)
                  .where(starts_at: [ from&.beginning_of_day, Time.current ].compact.max..)
                  .order(:starts_at)
    return shifts.none if invalid?

    shifts = shifts.where(starts_at: ..to.end_of_day) if to
    shifts = shifts.where(activities: { organization_id: organization_id }) if organization_id
    shifts = matching_text(shifts) if q.present?
    shifts = with_free_places(shifts) if open_only
    shifts
  end

  def filtered?
    q.present? || organization_id.present? || from.present? || to.present? || open_only
  end

  private

  def matching_text(shifts)
    pattern = "%#{Shift.sanitize_sql_like(q.strip)}%"
    shifts.where("activities.title ILIKE :p OR activities.location ILIKE :p OR activities.description ILIKE :p", p: pattern)
  end

  def with_free_places(shifts)
    shifts.where(<<~SQL.squish, confirmed: Signup.statuses[:confirmed])
      shifts.capacity > (SELECT COUNT(*) FROM signups WHERE signups.shift_id = shifts.id AND signups.status = :confirmed)
    SQL
  end

  def to_not_before_from
    errors.add(:to, "must not be before the start date") if from && to && to < from
  end
end
