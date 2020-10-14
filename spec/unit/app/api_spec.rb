require_relative '../../../app/api'
require 'rack/test'

module ExpenseTracker
  RSpec.describe API do
    include Rack::Test::Methods

    def app
      API.new(ledger: ledger)
    end

    def response_body
      JSON.parse(last_response.body)
    end

    let(:ledger) { instance_double('ExpenseTracker::Ledger') }

    describe 'POST /expenses' do
      context 'when the expense is successfully recorded' do
        let(:expense) { { 'some' => 'data' } }

        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(true, 417, nil))
        end

        it 'returns the expense id' do
          post '/expenses', JSON.generate(expense)
          expect(response_body).to include('expense_id' => 417)
        end

        it 'responds with a 200 (OK)' do
          post '/expenses', JSON.generate(expense)
          expect(last_response.status).to eq(200)
        end
      end

      context 'when the expense fails validation' do
        let(:expense) { { 'some' => 'data' } }

        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(false, nil, 'Expense incomplete'))
        end

        it 'returns an error message' do
          post '/expenses', JSON.generate(expense)
          expect(response_body).to include('error' => 'Expense incomplete')
        end

        it 'responds with a 422 (Unprocessable entity)' do
          post '/expenses', JSON.generate(expense)
          expect(last_response.status).to eq(422)
        end
      end
    end

    describe 'GET /expenses/:date' do
      context 'when expenses exist on the given date' do
        let(:expenses) do
          [
            Expense.new('Starbucks', 5.75,  Date.parse('2017-06-10')),
            Expense.new('Zoo',       15.25, Date.parse('2017-06-10'))
          ]
        end

        before do
          allow(ledger).to receive(:expenses_on)
          .with(Date.parse('2017-06-10'))
          .and_return(expenses)
        end

        it 'returns the expense records as JSON' do
          get '/expenses/2017-06-10'
          expect(response_body).to eq(expenses.map(&:serialize))
        end

        it 'responds with a 200 (OK)' do
          get '/expenses/2017-06-10'
          expect(last_response.status).to eq(200)
        end
      end

      context 'when there are no expenses on the given date' do
        let(:expenses) { [] }

        before do
          allow(ledger).to receive(:expenses_on)
          .with(Date.parse('2017-07-01'))
          .and_return(expenses)
        end

        it 'returns an empty array as JSON' do
          get '/expenses/2017-07-01'
          expect(response_body).to eq(expenses.map(&:serialize))
        end

        it 'responds with a 200 (OK)' do
          get '/expenses/2017-07-01'
          expect(last_response.status).to eq(200)
        end
      end
    end
  end
end
