class CreateAffirmCheckout < ActiveRecord::Migration
  def change
    create_table :spree_affirm_checkouts do |t|
      t.string     :token
      t.references :order
      t.references :payment_method
      t.timestamps
    end
  end
end
