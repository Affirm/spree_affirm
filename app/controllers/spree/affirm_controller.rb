module Spree
  class AffirmController < Spree::Api::BaseController
    def confirm
      order = find_current_order || raise(ActiveRecord::RecordNotFound)
      authorize! :update, order, order_token

      # TODO Membership check is specific to our implementation
      if !params[:checkout_token] || order.membership? || order.complete?
        return redirect_to checkout_path
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
          when :billing_address
            # FIXME(brian): pass the phone number to the |order| in a better place
            phone = order.bill_address.phone
            order.bill_address = generate_spree_address(_affirm_checkout.details['billing'])
            order.bill_address.phone = phone

          when :shipping_address
            # FIXME(brian): pass the phone number to the |order| in a better place
            phone = order.shipping_address.phone
            order.ship_address = generate_spree_address(_affirm_checkout.details['shipping'])
            order.ship_address.phone = phone

          when :billing_email
            order.email = _affirm_checkout.details['billing']['email']

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

      # transition to confirm or complete
      while order.next; end

      redirect_to checkout_path
    end

    def cancel
      redirect_to checkout_path
    end

    private

    def find_current_order
      if current_api_user&.persisted?
        current_api_user.orders.incomplete.order(:created_at).last
      elsif order_token
        Spree::Order.incomplete.where(token: order_token).order(:created_at).last
      end
    end

    def checkout_path
      ENV['AFFIRM_CHECKOUT_URL'] || '/checkout'
    end

    def payment_method
      Spree::PaymentMethod.find(params[:payment_method_id])
    end

    def provider
      payment_method.provider
    end

    def generate_spree_address(affirm_address)
      # find the state and country in spree
      _state    = Spree::State.find_by_abbr(affirm_address["address"]["region1_code"]) or
                  Spree::State.find_by_name(affirm_address["address"]["region1_code"])
      _country  = Spree::Country.find_by_iso3(affirm_address["address"]["country_code"]) or
                  Spree::Country.find_by_iso(affirm_address["address"]["country_code"])

      # try to get the name from first and last
      _firstname = affirm_address["name"]["first"] if affirm_address["name"]["first"].present?
      _lastname  = affirm_address["name"]["last"]  if affirm_address["name"]["last"].present?

      # fall back to using the full name if available
      if _firstname.nil? and _lastname.nil? and affirm_address["name"]["full"].present?
        _name_parts = affirm_address["name"]["full"].split " "
        _lastname   = _name_parts.pop
        _firstname  = _name_parts.join " "
      end

      # create new address
      _spree_address = Spree::Address.new(
        city:       affirm_address["address"]["city"],
        phone:      affirm_address["phone_number"],
        zipcode:    affirm_address["address"]["postal_code"],
        address1:   affirm_address["address"]["street1"],
        address2:   affirm_address["address"]["street2"],
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
