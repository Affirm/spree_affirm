class AddPaymentMethodToAffirmCheckout < ActiveRecord::Migration
  def change
    add_reference :spree_affirm_checkout, :payment_method
  end
end
