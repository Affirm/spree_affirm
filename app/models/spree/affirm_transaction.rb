module Spree
  # this is a hack to patch over the parts of Spree Affirm Checkouts that we
  # now need to point to Affirms Transaction API
  class AffirmTransaction < Spree::AffirmCheckout
  end
end
