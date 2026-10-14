# Grants a user a role inside one organization. Roles are per organization:
# the same user can organize one society and volunteer for another.
class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  enum :role, { volunteer: 0, organizer: 1 }, validate: true

  validates :user_id, uniqueness: { scope: :organization_id }
end
