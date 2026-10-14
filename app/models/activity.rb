class Activity < ApplicationRecord
  belongs_to :organization
  has_many :shifts, dependent: :destroy

  validates :title, presence: true, length: { maximum: 150 }
end
