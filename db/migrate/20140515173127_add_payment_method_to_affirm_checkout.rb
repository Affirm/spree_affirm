class AddPaymentMethodToAffirmCheckout < ActiveRecord::Migration
  def change
    add_reference :spree_affirm_checkouts, :payment_method
  end
end
