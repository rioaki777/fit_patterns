FactoryBot.define do
  factory :weight_entry do
    association :user
    sequence(:recorded_on) { |n| Date.current - n }
    weight_g { 70_000 }
    body_fat_bp { 1500 }
  end
end
