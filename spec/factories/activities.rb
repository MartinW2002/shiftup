FactoryBot.define do
  factory :activity do
    organization
    sequence(:title) { |n| "Activity #{n}" }
    location { "Campus" }
  end
end
