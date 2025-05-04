FactoryBot.define do
  factory :building_output do
    association :building
    association :resource
    quantity { 1 }
  end
end
