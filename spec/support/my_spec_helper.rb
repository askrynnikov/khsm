module MySpecHelper

  def generate_questions(number)
    number.times do
      FactoryGirl.create(:question)
    end
  end
end

RSpec.configure do |c|
  c.include MySpecHelper
end