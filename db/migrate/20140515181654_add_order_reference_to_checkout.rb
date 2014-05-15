class AddOrderReferenceToCheckout < ActiveRecord::Migration
  def change
    add_reference :spree_affirm_checkouts, :order
  end
end
