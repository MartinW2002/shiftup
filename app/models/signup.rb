class Signup < ApplicationRecord
  belongs_to :shift
  belongs_to :user

  enum :status, { confirmed: 0, waitlisted: 1, cancelled: 2 }, validate: true
  enum :attendance, { unmarked: 0, present: 1, absent: 2 }, prefix: true, validate: true

  scope :active, -> { where.not(status: :cancelled) }
  # Waiting list order: first come, first served by join time (id breaks ties).
  scope :waitlist_order, -> { waitlisted.order(:created_at, :id) }
end
