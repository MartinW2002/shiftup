class Shift < ApplicationRecord
  belongs_to :activity
  has_one :organization, through: :activity
  has_many :signups, dependent: :destroy

  # Runs before the dependent signups are destroyed.
  before_destroy :ensure_no_active_signups, prepend: true

  validates :starts_at, :ends_at, presence: true
  validates :capacity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :ends_after_start
  validate :starts_in_future, on: :create
  validate :capacity_covers_confirmed, on: :update
  validate :times_fixed_after_signups, on: :update

  scope :upcoming, -> { where(starts_at: Time.current..).order(:starts_at) }
  scope :overlapping, ->(starts_at, ends_at) { where("starts_at < ? AND ends_at > ?", ends_at, starts_at) }

  # Shifts that touch (one ends exactly when the other starts) do not overlap.
  def overlaps?(other)
    starts_at < other.ends_at && ends_at > other.starts_at
  end

  def started?
    starts_at <= Time.current
  end

  def confirmed_count
    signups.confirmed.count
  end

  def places_left
    [ capacity - confirmed_count, 0 ].max
  end

  def full?
    places_left.zero?
  end

  def waitlist_count
    signups.waitlisted.count
  end

  def time_range_text
    start_text = I18n.l(starts_at, format: :shift)
    end_format = starts_at.to_date == ends_at.to_date ? :clock : :shift
    "#{start_text}–#{I18n.l(ends_at, format: end_format)}"
  end

  private

  def ends_after_start
    return if starts_at.blank? || ends_at.blank?

    errors.add(:ends_at, "must be after the start time") unless ends_at > starts_at
  end

  def starts_in_future
    errors.add(:starts_at, "must be in the future") if starts_at.present? && started?
  end

  def capacity_covers_confirmed
    return if capacity.blank? || !capacity_changed?

    confirmed = confirmed_count
    errors.add(:capacity, "cannot be lower than the #{confirmed} volunteers already confirmed") if capacity < confirmed
  end

  # Moving a shift could silently create overlaps for volunteers already holding it.
  def times_fixed_after_signups
    return unless (starts_at_changed? || ends_at_changed?) && signups.active.exists?

    errors.add(:base, "Times cannot be changed after volunteers have signed up")
  end

  def ensure_no_active_signups
    return unless signups.active.exists?

    errors.add(:base, "This shift cannot be deleted because volunteers have signed up")
    throw :abort
  end
end
