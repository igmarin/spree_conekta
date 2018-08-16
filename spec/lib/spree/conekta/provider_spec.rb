require 'spec_helper'

describe Spree::Conekta::Provider do
  describe 'payment_procesor' do
    context 'the payment source is card' do
      it { expect(subject.payment_processor('card')).to be(Spree::Conekta::PaymentSource::Card) }
    end

    context 'the payment source is bank' do
      it { expect(subject.payment_processor('banorte')).to be(Spree::Conekta::PaymentSource::Bank) }
    end

    context 'the payment source is cash' do
      it { expect(subject.payment_processor('oxxo')).to be(Spree::Conekta::PaymentSource::Cash) }
    end
  end

  describe '#endpoint' do
    specify { expect(subject.endpoint).to eq 'charges' }
  end

  describe '#capture' do
    specify { expect(subject.capture(10, double)).to be_a_kind_of Spree::Conekta::Response }
  end

  describe '#authorize' do
    let(:variant) { FactoryBot.create(:variant) }
    let(:shipment) { FactoryBot.create(:shipment) }
    let(:line_item) { FactoryBot.create(:line_item, variant: variant) }
    let(:order) { FactoryBot.build(:order, number: 'foo123', shipments: [shipment], line_items: [line_item]) }
    let(:gateway_options) do
      {
        email: 'user@test.com',
        order_id: 'foo123',
        currency: 'MXN',
        billing_address: {
          name: 'User Test',
          phone: '123123232'
        },
        shipping_address: {
          address1: 'Fake St.',
          address2: '',
          city: 'San Francisco',
          state: 'California',
          country: 'US',
          zip: '94104'
        },
        shipping: 10.00,
      }
    end

    before do
      subject.auth_token = '1tv5yJp3xnVZ7eK67m4h'
      expect(Spree::Order).to receive(:find_by_number).and_return(order).twice
    end

    context 'When a credit card' do
      let(:method_params) do
        double 'method', first_name: 'foo',
                         last_name: 'bar',
                         verification_value: '123',
                         number: '4242424242424242',
                         year: '2014',
                         month: '8',
                         gateway_payment_profile_id: 'tok_test_visa_4242',
                         installments_number: nil
      end

      before do
        expect(subject).to receive(:source_method).and_return(Spree::Conekta::PaymentSource::Card).at_least(:once)
      end

      it 'authorizes a transaction' do
        VCR.use_cassette('card_transaction') do
          expect(subject.authorize(10000, method_params, gateway_options)).to be_success
        end
      end
    end

    context 'When a bank transaction' do
      let(:method_params) { {} }

      before do
        expect(subject).to receive(:source_method).and_return(Spree::Conekta::PaymentSource::Bank).at_least(:once)
      end

      it 'authorizes a transaction' do
        VCR.use_cassette('bank_transaction') do
          expect(subject.authorize(10000, method_params, gateway_options)).to be_success
        end
      end
    end

    context 'When a cash transaction' do
      let(:method_params) { {} }

      before do
        expect(subject).to receive(:source_method).and_return(Spree::Conekta::PaymentSource::Cash).at_least(:once)
      end

      it 'authorizes a transaction' do
        VCR.use_cassette('cash_transaction') do
          expect(subject.authorize(10000, method_params, gateway_options)).to be_success
        end
      end
    end
  end

  describe '#supports?' do
    it 'does not support amex' do
      expect(subject.supports?('american_express')).to be false
    end

    it 'supports visa' do
      expect(subject.supports?('visa')).to be true
    end

    it 'supports master card' do
      expect(subject.supports?('master')).to be true
    end
  end
end
