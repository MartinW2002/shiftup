class Signup < ApplicationRecord
  belongs_to :shift
  belongs_to :user

  enum :status, { confirmed: 0, waitlisted: 1, cancelled: 2 }, validate: true
  enum :attendance, { unmarked: 0, present: 1, absent: 2 }, prefix: true, validate: true

  validate :attendance_recordable, if: -> { attendance_changed? && !attendance_unmarked? }

  scope :active, -> { where.not(status: :cancelled) }
  # Waiting list order: first come, first served by join time (id breaks ties).
  scope :waitlist_order, -> { waitlisted.order(:created_at, :id) }
  # Promotions from the waiting list the volunteer has not been told about yet, for shifts
  # they still hold and that have not started.
  scope :unnotified_promotions, lambda {
    confirmed.where.not(promoted_at: nil).where(promotion_notified_at: nil)
             .joins(:shift).merge(Shift.upcoming)
  }
  # Removals by an organizer the volunteer has not been told about yet.
  scope :unnotified_removals, -> { where.not(removed_at: nil).where(removal_notified_at: nil) }

  # 1 for the first volunteer in line, nil unless waitlisted.
  def waitlist_position
    return unless waitlisted?

    shift.signups.waitlisted.where("(signups.created_at, signups.id) < (?, ?)", created_at, id).count + 1
  end

  private

  def attendance_recordable
    if !confirmed?
      errors.add(:attendance, "can only be recorded for confirmed volunteers")
    elsif !shift.started?
      errors.add(:attendance, "can only be recorded once the shift has started")
    end
  end
end
