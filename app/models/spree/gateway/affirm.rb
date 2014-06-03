module Spree
  class Gateway::Affirm < Gateway
    preference :api_key, :string
    preference :secret_key, :string
    preference :server, :string, default: 'www.affirm.com'
    preference :product_key, :string

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
        source_type:   "#{payment_source_class}"
      ).first

      return if _payment.nil?

      if _payment.pending?
        _payment.void_transaction!

      elsif _payment.completed? and _payment.can_credit?
        _payment.credit! _payment.credit_allowed.to_f

      end
    end
  end
end
