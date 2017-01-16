require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do

  let(:user) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:user, is_admin: true) }
  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }

  context 'Anon' do
    it 'kick from #show' do
      get :show, id: game_w_questions.id

      expect(response.status).not_to eq 200
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'may cause only #show' do
      get :show, id: game_w_questions.id

      # expect(assigns(:game)).to eq(game_w_questions)
      # expect(response).to render_template(:show)
    end
  end

  context 'Usual user' do
    before(:each) do
      sign_in user
    end

    it 'creates game' do
      generate_questions(60)

      post :create

      game = assigns(:game)

      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)

      expect(response).to redirect_to game_path(game)
      expect(flash[:notice]).to be
    end

    it '#show game' do
      get :show, id: game_w_questions.id

      game = assigns(:game)

      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)

      expect(response.status).to eq 200
      expect(response).to render_template('show')
    end

    it 'answer correct' do
      put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key

      game = assigns(:game)

      expect(game.finished?).to be_falsey
      expect(game.current_level).to be > 0

      expect(response).to redirect_to game_path(game)
      expect(flash.empty?).to be_truthy
    end

    it 'show alien game' do
      new_user = FactoryGirl.create(:user)
      alien_game = FactoryGirl.create(:game_with_questions, user: new_user)

      get :show, id: alien_game.id

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be
    end

    it 'user take money' do
      game_w_questions.answer_current_question!(game_w_questions.current_game_question.correct_answer_key)

      put :take_money, id: game_w_questions.id

      game = assigns(:game)
      expect(game.finished?).to be_truthy
      expect(game.prize).to eq(100)

      expect(response).to redirect_to user_path(user)
      expect(flash[:warning]).to be

      expect { user.reload }.to change(user, :balance).by(100)
    end

    it 'user tries to start the second game' do
      expect(game_w_questions.finished?).to be_falsey

      expect { post :create }.to change(Game, :count).by(0)

      game = assigns(:game)
      expect(game).to be_nil

      expect(response).to redirect_to(game_path(game_w_questions))
      expect(flash[:alert]).to be
    end

    it 'answer not correct' do
      not_correct_answer_key = (%w(a b c d) - [game_w_questions.current_game_question.correct_answer_key]).sample
      put :answer, id: game_w_questions.id, letter: not_correct_answer_key

      game = assigns(:game)
      expect(game.finished?).to be true

      expect(response).to redirect_to user_path(user)
    end
  end
end
