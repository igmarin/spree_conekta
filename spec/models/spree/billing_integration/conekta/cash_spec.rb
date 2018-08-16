require 'spec_helper'

describe Spree::BillingIntegration::ConektaGateway::Cash do
  describe '#gateway_class' do
    specify { expect(subject.gateway_class).to eq Spree::Conekta::Provider }
  end

  describe '#payment_source_class' do
    specify { expect(subject.payment_source_class).to eq Spree::ConektaPayment }
  end

  describe '#card?' do
    specify { expect(subject.card?).to eq(false) }
  end

  describe '#auto_capture?' do
    specify { expect(subject.auto_capture?).to eq(false) }
  end

  describe '#method_type' do
    specify { expect(subject.method_type).to eq 'conekta' }
  end

  describe '#partial_name' do
    specify { expect(subject.partial_name).to eq 'conekta' }
  end
end
