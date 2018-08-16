module Spree::Conekta
  class PaymentsController < Spree::StoreController
    helper Spree::OrdersHelper
    skip_before_action :verify_authenticity_token, only: :create

    def show
      @order = Spree::Order.find_by_number(params[:id])
      @order_details = @order.last_payment_details.params
    end

    def create
      PaymentNotificationHandler.new(params).perform_action if params['type'] == 'order.paid'
      head :ok, content_type: "text/html"
    end
  end
end
