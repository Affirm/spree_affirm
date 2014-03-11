module Spree
  class AffirmCheckout
      attr_accessor :charge_id
      def initialize(charge_id)
          @charge_id = charge_id
      end
      def valid?
          true
      end
  end
end
