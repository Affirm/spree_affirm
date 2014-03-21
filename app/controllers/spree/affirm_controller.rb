module Spree
  class AffirmController < StoreController
    #the confirm will do it's own protection by making calls to affirm
    protect_from_forgery :except => [:confirm]

    def confirm
      order = current_order || raise(ActiveRecord::RecordNotFound)
      if !params[:checkout_token]
        flash[:notice] = "Invalid order confirmation data."
        return redirect_to checkout_state_path(current_order.state)
      end
      if order.complete?
        flash[:notice] = "Order already completed."
        return redirect_to checkout_state_path(current_order.state)
      end
      affirm_payment = order.payments.create!({
        :amount => order.total,
        :payment_method => payment_method
      })
      checkout_token = params[:checkout_token]
      #dangerous... but this seems the least intrusive
      #we don't want to pollute other payments with this source
      #so only override on confirm
      affirm_payment.instance_eval do
          @affirm_checkout_token = checkout_token
          def source
              Spree::AffirmCheckout.new(@affirm_checkout_token)
          end
      end
      logger.info "affirm payment source: #{affirm_payment.source.inspect}"
      order.next
      if order.complete?
        flash.notice = Spree.t(:order_processed_successfully)
        flash[:commerce_tracking] = "nothing special"
        redirect_to completion_route(order)
      else
        flash.notice = "There was an error completing your order"
        redirect_to checkout_state_path(order.state)
      end
    end

    def cancel
      flash[:notice] = "Don't want to use Affirm? No problems."
      redirect_to checkout_state_path(current_order.state)
    end

    private

    def payment_method
      Spree::PaymentMethod.find(params[:payment_method_id])
    end

    def provider
      payment_method.provider
    end

    def completion_route(order)
      order_path(order, :token => order.token)
    end
  end
end
