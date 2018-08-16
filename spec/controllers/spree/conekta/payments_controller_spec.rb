require 'spec_helper'
require 'celluloid'

describe Spree::Conekta::PaymentsController do
  let(:user) { FactoryBot.create(:user) }
  let(:order) { FactoryBot.create(:order_with_totals) }
  let(:payment_method) { FactoryBot.create(:credit_card_payment_method, environment: 'test') }
  let(:payment) { FactoryBot.create(:payment, order: order, state: 'pending', amount: order.outstanding_balance, payment_method: payment_method) }
  let(:conekta_response) do
    {
      "data"=>{
        "object"=>{
          "id"=>"5213ecbf9328af245f00000a",
          "livemode"=>"false",
          "created_at"=>"1377037504",
          "status"=>"paid",
          "currency"=>"MXN",
          "description"=>"R706552773-5TAPHAJT",
          "failure_code"=>"",
          "failure_message"=>"",
          "amount"=>"10040",
          "processed_at"=>"0",
          "fee"=>"233",
          "reference_id"=>"RT#{rand(0..1000)}-XCVBC",
          "customer"=>{
            "name"=>"Jonathan Garay",
            "phone"=>"3123123",
            "email"=>""
          }
        }
      },
      "created_at"=>"1377037506",
      "type"=>"charge.paid",
      "id"=>"5213ecc29328af245f00000f"
    }
  end
  let(:order_number){ conekta_response['data']['object']['reference_id'].split('-')[0] }

  describe 'create' do
    before { order.number = order_number }

    context 'The order is completed and a pending payment exist' do
      before do
        post :create, params: conekta_response
      end

      it 'should mark a payment as completed' do
        sleep 2
        expect(response.body).to be_blank
      end
    end

    context 'The order is completed and a pending payment exist but the charge is not paid' do
      before do
        allow_any_instance_of(Spree::Conekta::PaymentNotificationHandler).to receive(:delay).and_return(1)
        post :create, params: conekta_response.merge!('type' => 'charge.created')
      end

      it 'It should do nothing if the charge notification is not paid' do
        sleep 2
        expect_any_instance_of(Spree::Conekta::PaymentNotificationHandler).to_not receive(:perform_action)
        expect(response.body).to be_blank
      end
    end
  end
end
