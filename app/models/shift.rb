class Shift < ApplicationRecord
  belongs_to :activity
  has_one :organization, through: :activity
  has_many :signups, dependent: :destroy

  validates :starts_at, :ends_at, presence: true
  validates :capacity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :ends_after_start

  scope :upcoming, -> { where(starts_at: Time.current..).order(:starts_at) }
  scope :overlapping, ->(starts_at, ends_at) { where("starts_at < ? AND ends_at > ?", ends_at, starts_at) }

  def overlaps?(other)
    starts_at < other.ends_at && ends_at > other.starts_at
  end

  private

  def ends_after_start
    return if starts_at.blank? || ends_at.blank?

    errors.add(:ends_at, "must be after the start time") unless ends_at > starts_at
  end
end
