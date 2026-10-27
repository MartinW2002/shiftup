class Activity < ApplicationRecord
  belongs_to :organization
  has_many :shifts, dependent: :destroy

  # Runs before the dependent shifts are destroyed.
  before_destroy :ensure_no_active_signups, prepend: true

  validates :title, presence: true, length: { maximum: 150 }
  validates :location, length: { maximum: 150 }
  validates :description, length: { maximum: 2000 }

  private

  def ensure_no_active_signups
    return unless Signup.active.joins(:shift).where(shifts: { activity_id: id }).exists?

    errors.add(:base, "This activity cannot be deleted because volunteers have signed up for its shifts")
    throw :abort
  end
end
