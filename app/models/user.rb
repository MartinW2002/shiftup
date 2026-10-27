class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # :recoverable (password reset by email) is left out because the demo deployment sends no email.
  devise :database_authenticatable, :registerable,
         :rememberable, :validatable

  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships
  has_many :signups, dependent: :destroy
  # Runs before the sign-ups are destroyed, so confirmed places are released through
  # ShiftCancellation (which promotes the waiting list) rather than silently deleted.
  before_destroy :ensure_no_upcoming_signups, prepend: true
  has_many :confirmed_signups, -> { confirmed }, class_name: "Signup", inverse_of: :user
  has_many :confirmed_shifts, through: :confirmed_signups, source: :shift

  validates :name, presence: true, length: { maximum: 100 }

  def membership_in(organization)
    memberships.find_by(organization: organization)
  end

  def member_of?(organization)
    membership_in(organization).present?
  end

  def organizer_of?(organization)
    membership_in(organization)&.organizer? || false
  end

  private

  def ensure_no_upcoming_signups
    return unless signups.active.joins(:shift).merge(Shift.upcoming).exists?

    errors.add(:base, "Cancel your upcoming shifts and waiting list places before deleting your account")
    throw :abort
  end
end
