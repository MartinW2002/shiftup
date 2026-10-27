require 'rails_helper'

# Policies inherit from ApplicationPolicy, so anything a policy does not explicitly allow is denied.
RSpec.describe ApplicationPolicy, type: :policy do
  subject { described_class.new(create(:user), Object.new) }

  it { is_expected.to forbid_all_actions }
  it { is_expected.to forbid_actions(%i[index show create new update edit destroy]) }

  it "requires each policy scope to define what it returns" do
    expect { described_class::Scope.new(create(:user), Organization).resolve }.to raise_error(NoMethodError, /define #resolve/)
  end
end
