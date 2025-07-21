FactoryBot.define do
  factory :village_resource do
    village
    resource
    count { 1 }
  end
end
