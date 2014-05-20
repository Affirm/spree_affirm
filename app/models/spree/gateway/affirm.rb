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
  end
end
