module Spree
  class AffirmCheckout < ActiveRecord::Base
    belongs_to :payment_method
    belongs_to :order

    scope :with_payment_profile, -> { all }

    def name
      "Affirm Checkout"
    end

    def details
      @details ||= payment_method.provider.get_checkout token
    end

    def actions
      %w{capture void credit}
    end

    # Indicates whether its possible to capture the payment
    def can_capture?(payment)
      (payment.pending? || payment.checkout?) && !payment.response_code.blank?
    end

    # Indicates whether its possible to void the payment.
    def can_void?(payment)
      !payment.void? && payment.pending? && !payment.response_code.blank?
    end

    # Indicates whether its possible to credit the payment.  Note that most gateways require that the
    # payment be settled first which generally happens within 12-24 hours of the transaction.
    def can_credit?(payment)
      return false unless payment.completed?
      return false unless payment.order.payment_state == 'credit_owed'
      payment.credit_allowed > 0
    end
  end
end
