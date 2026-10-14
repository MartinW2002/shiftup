FactoryBot.define do
  factory :signup do
    shift
    user
    status { :confirmed }

    trait :waitlisted do
      status { :waitlisted }
    end

    trait :cancelled do
      status { :cancelled }
    end
  end
end
