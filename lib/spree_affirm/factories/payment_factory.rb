FactoryGirl.define do
  factory :affirm_payment, class: Spree::Payment do
    amount 45.75
    association(:payment_method, factory: :credit_card_payment_method)
    association(:source, factory: :affirm_checkout)
    order
    state 'checkout'
    response_code '12345'
  end
end
