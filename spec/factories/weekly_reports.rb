FactoryBot.define do
  factory :weekly_report do
    association :user
    period_start { 1.week.ago.to_date }
    period_end { Date.current }
    avg_weight_g { 70_000 }
    avg_body_fat_bp { 1500 }
    total_calories_kcal { 2100 }
    total_workout_min { 210 }
  end
end
