require 'rails_helper'

RSpec.describe Membership, type: :model do
  subject { build(:membership) }

  it { is_expected.to define_enum_for(:role).with_values(volunteer: 0, organizer: 1).validating }
  it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:organization_id) }
end
