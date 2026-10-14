FactoryBot.define do
  factory :membership do
    user
    organization
    role { :volunteer }

    trait :organizer do
      role { :organizer }
    end
  end
end
