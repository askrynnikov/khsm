require 'rails_helper'

RSpec.describe "users/index", type: :view do
  before(:each) do
    assign(:users, [
      FactoryGirl.build_stubbed(:user, name: 'Андрей', balance: 5000),
      FactoryGirl.build_stubbed(:user, name: 'Александр', balance: 3000),
    ])

    render
  end

  it 'renders player names' do
    expect(rendered).to match 'Андрей'
    expect(rendered).to match 'Александр'
  end

  it 'renders player balances' do
    expect(rendered).to match '5 000 ₽'
    expect(rendered).to match '3 000 ₽'
  end

  it 'renders player names in right order' do
    expect(rendered).to match /Андрей.*Александр/m
  end
end
