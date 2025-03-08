FactoryBot.define do
  factory :tile do
    sequence(:x) { |n| n }
    sequence(:y) { |n| n }
  end
end
