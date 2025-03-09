FactoryBot.define do
  factory :resource do
    sequence(:name) { |n| "Resource#{n}" }
  end
end
