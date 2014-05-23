require 'spec_helper'

describe Spree::AffirmController do
  let(:user) { FactoryGirl.create(:user) }
  let(:checkout) { FactoryGirl.build(:affirm_checkout) }
  let(:bad_billing_checkout) { FactoryGirl.build(:affirm_checkout, billing_address_mismatch: true) }
  let(:bad_shipping_checkout) { FactoryGirl.build(:affirm_checkout, shipping_address_mismatch: true) }
  let(:bad_email_checkout) { FactoryGirl.build(:affirm_checkout, billing_email_mismatch: true) }


  describe "POST confirm" do

    def post_request(token, payment_id)
      post :confirm, checkout_token: token, payment_method_id: payment_id, use_route: 'spree'
    end

    before do
      controller.stub authenticate_spree_user!: true
      controller.stub spree_current_user: user
    end

    context "when the checkout matches the order" do
      before do
        Spree::AffirmCheckout.stub new: checkout
        controller.stub current_order: checkout.order
      end

      context "when no checkout_token is provided" do
        it "redirects to the current order state" do
          post_request(nil, nil)
          expect(response).to redirect_to(controller.checkout_state_path(checkout.order.state))
        end
      end


      context "when the order is complete" do
        before do
          checkout.order.state = 'complete'
        end
        it "redirects to the current order state" do
          post_request '123456789', checkout.payment_method.id
          expect(response).to redirect_to(controller.checkout_state_path(checkout.order.state))
        end
      end

      it "creates a new payment" do
        # expect do
        post_request "123423423", checkout.payment_method.id
        # end.to change(checkout.order.payments.count)

        expect(checkout.order.payments.first.source).to eq(checkout)
      end

    end

    context "when the billing_address does not match the order" do
      before do
        Spree::AffirmCheckout.stub new: bad_billing_checkout
        state = FactoryGirl.create(:state, abbr: bad_billing_checkout.details['billing']['address']['region1_code'])
        Spree::State.stub find_by_abbr: state, find_by_name: state
        controller.stub current_order: bad_billing_checkout.order
      end

      it "creates a new address record for the order" do
        _old_billing_address = bad_billing_checkout.order.bill_address
        post_request '12345789', bad_billing_checkout.payment_method.id

        expect(bad_billing_checkout.order.bill_address).not_to be(_old_billing_address)
        expect(bad_billing_checkout.valid?).to be(true)
      end
    end


    context "when the shipping_address does not match the order" do
      before do
        Spree::AffirmCheckout.stub new: bad_shipping_checkout
        state = FactoryGirl.create(:state, abbr: bad_shipping_checkout.details['shipping']['address']['region1_code'])
        Spree::State.stub find_by_abbr: state, find_by_name: state
        controller.stub current_order: bad_shipping_checkout.order
      end

      it "creates a new address record for the order" do
        _old_shipping_address = bad_shipping_checkout.order.ship_address
        post_request '12345789', bad_shipping_checkout.payment_method.id

        expect(bad_shipping_checkout.order.ship_address).not_to be(_old_shipping_address)
        expect(bad_shipping_checkout.valid?).to be(true)
      end
    end



    context "when the billing_email does not match the order" do
      before do
        Spree::AffirmCheckout.stub new: bad_email_checkout
        controller.stub current_order: bad_email_checkout.order
      end

      it "updates the billing_email on the order" do
        _old_email = bad_email_checkout.order.email
        post_request '12345789', bad_email_checkout.payment_method.id

        expect(bad_email_checkout.order.email).not_to be(_old_email)
        expect(bad_email_checkout.valid?).to be(true)
      end
    end


    context "there is no current order" do
      before(:each) do
        controller.stub current_order: nil
      end

      it "raises an ActiveRecord::RecordNotFound error" do
        expect do
          post_request nil, nil
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end