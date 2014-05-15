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

      _affirm_checkout = Spree::AffirmCheckout.new(
        order: order,
        token: params[:checkout_token],
        payment_method: payment_method
      )

      # check if data needs to be updated
      unless _affirm_checkout.valid?

        _affirm_checkout.errors.each do |field, error|
          case field
          when "billing_address"
            order.bill_address = generate_spree_address(_affirm_checkout.details['billing'])

          when "shipping_address"
            order.ship_address = generate_spree_address(_affirm_checkout.details['shipping'])

          when "billing_email"
            order.email = _affirm_checkout.details["billing"]["email"]

          end
        end

        order.save
      end

      _affirm_checkout.save

      _affirm_payment = order.payments.create!({
        payment_method: payment_method,
        amount: order.total,
        source: _affirm_checkout
      })

      order.next

      if order.complete?
        flash.notice = Spree.t(:order_processed_successfully)
        flash[:commerce_tracking] = "nothing special"
      end

      redirect_to checkout_state_path(order.state)
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

    def generate_spree_address(affirm_address)
      # find the state and country in spree
      _state    = Spree::State.find_by_abbr(affirm_address["address"]["state"])
      _country  = Spree::Country.find_by_iso(affirm_address["address"]["coutnry"])

      # try to get the name from first and last
      _firstname = affirm_address["address"]["name"]["first"] if affirm_address["address"]["name"]["first"]
      _lastname  = affirm_address["address"]["name"]["last"]  if affirm_address["address"]["name"]["last"]

      # fall back to using the full name if available
      if _firstname.nil? and _lastname.nil? and affirm_address["address"]["name"]["full"]
        _name_parts = affirm_address["address"]["name"]["full"].split " "
        _lastname   = _name_parts.pop
        _firstname  = _name_parts.join " "
      end

      # create new address
      _spree_address = Spree::Address.new(
        city:       affirm_address["address"]["city"],
        phone:      affirm_address["phone_number"],
        zipcode:    affirm_address["address"]["zipcode"],
        address1:   affirm_address["address"]["line1"],
        address2:   affirm_address["address"]["line2"],
        state:      _state,
        country:    _country,
        lastname:   _lastname,
        firstname:  _firstname
      )

      _spree_address.save
      _spree_address
    end
  end
end
