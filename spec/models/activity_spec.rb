require 'rails_helper'

RSpec.describe Activity, type: :model do
  it { is_expected.to belong_to(:organization) }
  it { is_expected.to validate_presence_of(:title) }
end
