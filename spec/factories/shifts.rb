FactoryBot.define do
  factory :shift do
    activity
    starts_at { 1.day.from_now.change(hour: 10) }
    ends_at { starts_at + 2.hours }
    capacity { 2 }

    # Shifts must start in the future when created, so past shifts skip validation.
    trait :past do
      starts_at { 2.days.ago.change(hour: 10) }
      to_create { |shift| shift.save!(validate: false) }
    end
  end
end
