require 'rails_helper'

RSpec.describe Organization, type: :model do
  subject { build(:organization) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name).case_insensitive }

  it "lists only its own organizers" do
    organization = create(:organization)
    organizer = create(:membership, :organizer, organization: organization).user
    create(:membership, organization: organization)
    create(:membership, :organizer)

    expect(organization.organizers).to contain_exactly(organizer)
  end
end
