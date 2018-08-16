require 'spec_helper'

describe Spree::BillingIntegration::ConektaGateway::Card do
  describe '#gateway_class' do
    specify { expect(subject.gateway_class).to eq Spree::Conekta::Provider }
  end

  describe '#payment_source_class' do
    specify { expect(subject.payment_source_class).to eq Spree::CreditCard }
  end

  describe '#card?' do
    specify { expect(subject.card?).to eq(true) }
  end

  describe '#auto_capture?' do
    specify { expect(subject.auto_capture?).to eq(true) }
  end
end
