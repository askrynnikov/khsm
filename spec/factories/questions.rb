FactoryGirl.define do
  factory :question do
    answer1 { "#{rand(2001)}" }
    answer2 { "#{rand(2002)}" }
    answer3 { "#{rand(2003)}" }
    answer4 { "#{rand(2004)}" }

    sequence(:text) { |n| "В каком году была косм. одиссея #{n}?" }

    sequence(:level) { |n| n % 15 }
  end
end
