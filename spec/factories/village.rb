FactoryBot.define do
  factory :village do
    association :user
    association :tile
  end
end
