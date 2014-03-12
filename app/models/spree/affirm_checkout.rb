module Spree
  class AffirmCheckout
      attr_accessor :charge_token
      def initialize(charge_token)
          @charge_token = charge_token
      end
      def valid?
          true
      end
  end
end
