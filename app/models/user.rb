class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships
  has_many :signups, dependent: :destroy

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
end
