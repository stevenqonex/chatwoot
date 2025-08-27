FactoryBot.define do
  factory :channel_tiktok, class: 'Channel::Tiktok' do
    business_id { Faker::Alphanumeric.alphanumeric(number: 10) }
    access_token { Faker::Alphanumeric.alphanumeric(number: 32) }
    expires_at { 1.hour.from_now }
    webhook_verify_token { Faker::Alphanumeric.alphanumeric(number: 16) }
    provider_config { {} }
    account
  end
end
