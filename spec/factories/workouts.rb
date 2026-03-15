FactoryBot.define do
  factory :workout do
    association :user
    recorded_on { Date.current - 1 }
    kind { "running" }
    duration_min { 30 }
    calories_kcal { 300 }
    intensity { 5 }
  end
end
