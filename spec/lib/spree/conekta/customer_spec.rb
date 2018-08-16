require 'spec_helper'

describe Spree::Conekta::Customer do
  let(:user) { FactoryBot.create(:user) }
  let(:credit_cards) { double('credit_cards') }
  let(:token)        { '123456' }

  subject { described_class.new(user) }

  before do
    subject.auth_token = '1tv5yJp3xnVZ7eK67m4h'
  end

  context 'When the user does not has a customer associated' do
    before do
      expect(user).to receive(:gateway_customer_profile_id).and_return('cus_e7inii51RjUPsMbP8')
    end

    it 'creates a new customer' do
      VCR.use_cassette('create_customer') do
        expect(subject.id).to_not be_nil
      end
    end
  end

  context 'When the user has a customer associated' do
    before do
      expect(user).to receive(:gateway_customer_profile_id).and_return('123')
    end

    it 'uses the users customer id' do
      expect(subject.id).to eq '123'
    end
  end

  describe '#add_credit_card' do
    before do
      expect(subject).to receive(:credit_cards).and_return(credit_cards)
    end

    it 'adds a credit card to te customer' do
      expect(credit_cards).to receive(:add).with(token)
      subject.add_credit_card(token)
    end
  end

  describe '#credit_cards' do
    before do
      expect(subject).to receive(:id).and_return('cus_e7inii51RjUPsMbP8')
    end

    it 'fetch credit cards from conekta' do
      VCR.use_cassette('customer_fetch_credit_cards') do
        expect(subject.credit_cards).to be_a_kind_of Spree::Conekta::CreditCardCollection
      end
    end
  end

  describe 'endpoint' do
    specify { expect(subject.endpoint).to eq 'customers' }
  end
end
