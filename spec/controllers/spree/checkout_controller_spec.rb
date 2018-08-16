require 'spec_helper'

describe Spree::CheckoutController do
  let(:token) { 'some_token' }
  let(:user) { stub_model(Spree::LegacyUser) }
  let(:order) { FactoryBot.create(:order_with_totals) }

  before do
    expect(controller).to receive(:try_spree_current_user).and_return(user)
    expect(controller).to receive(:current_order).and_return(order)
  end
end
