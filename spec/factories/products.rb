FactoryBot.define do
  factory :product do
    name { Faker::Beer.name }
    code { "GR#{Faker::Number.between(from: 1, to: 10)}" }
    price { Faker::Number.between(from: 3.0, to: 15.0).round(2) }
    image_url { Faker::Internet.url }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
  end
end
