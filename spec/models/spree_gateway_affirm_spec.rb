require 'spec_helper'

describe Spree::Gateway::Affirm do
  let(:affirm_payment) { FactoryGirl.create(:affirm_payment) }
  let(:affirm_checkout) { FactoryGirl.create(:affirm_checkout) }

  describe '#provider_class' do
    it "returns the Affirm ActiveMerchant class" do
      expect(affirm_payment.payment_method.provider_class).to be(ActiveMerchant::Billing::Affirm)
    end
  end

  describe '#payment_source_class' do
    it "returns the affirm_checkout class" do
      expect(affirm_payment.payment_method.payment_source_class).to be(Spree::AffirmCheckout)
    end
  end

  describe '#source_required?' do
    it "returns true" do
      expect(affirm_payment.payment_method.source_required?).to be(true)
    end
  end

  describe '#method_type?' do
    it 'returns "affirm"' do
      expect(affirm_payment.payment_method.method_type).to eq("affirm")
    end
  end

  describe '#actions?' do
    it "retuns capture, void and credit" do
      expect(affirm_payment.payment_method.actions).to eq(['capture', 'void', 'credit'])
    end
  end

  describe '#supports?' do
    it "returns true if the source is an AffirmCheckout" do
      expect(affirm_payment.payment_method.supports?(affirm_checkout)).to be(true)
    end

    it "returns false when the source is not an affirm" do
      expect(affirm_payment.payment_method.supports?(6)).to be(false)
      expect(affirm_payment.payment_method.supports?(affirm_payment)).to be(false)
      expect(affirm_payment.payment_method.supports?(Spree::Order.new)).to be(false)
    end
  end

end