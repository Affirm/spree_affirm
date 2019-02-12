module Spree
  class Gateway::Affirm < Gateway
    preference :api_key, :string
    preference :secret_key, :string
    preference :test_mode, :boolean, default: true
    preference :server, :string, default: 'sandbox.affirm.com'

    def provider_class
      ActiveMerchant::Billing::Affirm
    end

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

    def supports?(source)
      source.is_a? payment_source_class
    end

    def self.version
      Gem::Specification.find_by_name('spree_affirm').version.to_s
    end

    def cancel(charge_ari)
      _payment = Spree::Payment.valid.where(
        response_code: charge_ari,
        source_type:   payment_source_class.to_s
      ).first

      return if _payment.nil?

      if _payment.pending?
        _payment.void_transaction!

      elsif _payment.completed? && _payment.can_credit?

        # create adjustment
        _payment.order.adjustments.create(
            label: "Refund - Canceled Order",
            amount: -_payment.credit_allowed.to_f,
            order: _payment.order
        )
        Spree::OrderUpdater.new(_payment.order).update
        provider.refund(_payment.credit_allowed.to_money.cents, charge_ari)
      
      end
    end
  end
end
