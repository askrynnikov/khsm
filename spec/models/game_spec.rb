require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do
  # pending "add some examples to (or delete) #{__FILE__}"

  let(:user) { FactoryGirl.create(:user) }
  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }

  context 'game mechanics' do
    it 'Game.create_game_for_user! new correct game' do
      generate_questions(60)

      game = nil
      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(
        change(GameQuestion, :count).by(15)
      )

      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)

      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end

    it 'answer correct continues' do
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      expect(game_w_questions.current_level).to eq(level + 1)

      expect(game_w_questions.previous_game_question).to eq q
      expect(game_w_questions.current_game_question).not_to eq q

      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end

    it 'take_money! work correct' do
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)

      game_w_questions.take_money!

      expect(game_w_questions.finished?).to be_truthy
      expect(game_w_questions.prize).to be > 0
      expect(game_w_questions.status).to eq :money

      expect(user.balance).to eq game_w_questions.prize
    end
  end

# группа тестов на проверку статуса игры
  context '.status' do
    # перед каждым тестом "завершаем игру"
    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be_truthy
    end

    it ':won' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq(:won)
    end

    it ':fail' do
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:fail)
    end

    it ':timeout' do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:timeout)
    end

    it ':money' do
      expect(game_w_questions.status).to eq(:money)
    end
  end

# группа тестов на проверку метода answer_current_question
  context '.answer_current_question' do
    it 'answer correct' do
      expect {
        expect(
          game_w_questions.answer_current_question!(game_w_questions.current_game_question.correct_answer_key)
        ).to be true
      }.to change(game_w_questions, :current_level).by(1)

      expect(game_w_questions.status).to eq(:in_progress)

    end

    it 'last answer correct' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max

      expect {
        expect(
          game_w_questions.answer_current_question!(game_w_questions.current_game_question.correct_answer_key)
        ).to be true
      }.to change(user, :balance).by(Game::PRIZES.max)

      expect(game_w_questions.status).to eq(:won)
      expect(game_w_questions.prize).to eq(Game::PRIZES.max)
    end

    it 'answer not correct without guaranteed sum' do
      not_correct_answer_key = (['a', 'b', 'c', 'd'] - [game_w_questions.current_game_question.correct_answer_key]).sample

      expect {
        expect(
          game_w_questions.answer_current_question!(not_correct_answer_key)
        ).to be false
      }.to change(user, :balance).by(0)

      expect(game_w_questions.status).to eq(:fail)
    end

    it 'answer not correct with guaranteed sum' do
      6.times do
        game_w_questions.answer_current_question!(game_w_questions.current_game_question.correct_answer_key)
      end

      not_correct_answer_key = (['a', 'b', 'c', 'd'] - [game_w_questions.current_game_question.correct_answer_key]).sample
      expect {
        expect(
          game_w_questions.answer_current_question!(not_correct_answer_key)
        ).to be false
      }.to change(user, :balance).by(1_000)

      expect(game_w_questions.status).to eq(:fail)
    end


    it 'answer time out without guaranteed sum' do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.finished_at = Time.now

      expect {
        expect(
          game_w_questions.answer_current_question!(game_w_questions.current_game_question.correct_answer_key)
        ).to be false
      }.to change(user, :balance).by(0)

      expect(game_w_questions.status).to eq(:timeout)
    end

    it 'answer time out with guaranteed sum' do
      6.times do
        game_w_questions.answer_current_question!(game_w_questions.current_game_question.correct_answer_key)
      end

      game_w_questions.created_at = 1.hour.ago
      game_w_questions.finished_at = Time.now

      expect {
        expect(
          game_w_questions.answer_current_question!(game_w_questions.current_game_question.correct_answer_key)
        ).to be false
      }.to change(user, :balance).by(1_000)

      expect(game_w_questions.status).to eq(:timeout)
    end
  end

  context 'inspection methods' do
    it 'current_game_question' do
      expect(game_w_questions.current_game_question).to eq(
                                                          game_w_questions.game_questions[0]
                                                        )
    end
    it 'previous_game_question' do
      expect(game_w_questions.previous_game_question).to be nil
    end
    it 'previous_level' do
      expect(game_w_questions.previous_level).to eq(-1)
    end
  end
end
