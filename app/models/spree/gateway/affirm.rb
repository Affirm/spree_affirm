module Spree
  class Gateway::Affirm < Gateway
    preference :api_key, :string
    preference :secret_key, :string
    preference :server, :string, default: 'www.affirm.com'
    preference :product_key, :string

    def provider_class
      ActiveMerchant::Billing::Affirm
    end

    #this is NOT a active record! it's a hack!
    def payment_source_class
        Spree::AffirmCheckout
    end

    def source_required?
        true
    end

    def method_type
      'affirm'
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

    def supports?(source)
        source.is_a? payment_source_class
    end
  end
end
