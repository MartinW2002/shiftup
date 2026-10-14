FactoryBot.define do
  factory :shift do
    activity
    starts_at { 1.day.from_now.change(hour: 10) }
    ends_at { starts_at + 2.hours }
    capacity { 2 }
  end
end
