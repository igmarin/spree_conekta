require 'spec_helper'

describe Spree::BillingIntegration::ConektaGateway do
  context 'When Spree::Config[:auto_capture] is set to true' do
    before do
      Spree::Config[:auto_capture] = true
    end

    specify { expect(subject.auto_capture?).to eq(false) }
  end
end
