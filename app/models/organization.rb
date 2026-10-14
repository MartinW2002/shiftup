class Organization < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :activities, dependent: :destroy
  has_many :shifts, through: :activities

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }

  def organizers
    users.merge(Membership.organizer)
  end
end
