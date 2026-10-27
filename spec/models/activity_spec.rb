require 'rails_helper'

RSpec.describe Activity, type: :model do
  it { is_expected.to belong_to(:organization) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_length_of(:title).is_at_most(150) }
  it { is_expected.to validate_length_of(:location).is_at_most(150) }
  it { is_expected.to validate_length_of(:description).is_at_most(2000) }

  describe "deleting" do
    let(:activity) { create(:activity) }
    let(:shift) { create(:shift, activity: activity) }

    it "is refused while volunteers are signed up for one of its shifts" do
      create(:signup, :waitlisted, shift: shift)

      expect(activity.destroy).to be false
      expect(activity.errors[:base]).to include("This activity cannot be deleted because volunteers have signed up for its shifts")
      expect(shift.reload).to be_persisted
    end

    it "removes its shifts when nobody is signed up" do
      create(:signup, :cancelled, shift: shift)

      expect { activity.destroy }.to change(Shift, :count).by(-1)
    end
  end
end
