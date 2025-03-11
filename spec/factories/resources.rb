FactoryBot.define do
  factory :resource do
    sequence(:name) { |n| "Resource#{n}" }
    after(:create) do |resource|
      resource.tags << create(:tag)
    end
  end
end
