require 'spec_helper'

describe "Affirm setup", :js => true do
  stub_authorization!

  before(:each) do
    visit spree.admin_path
    click_link "Configuration"
  end

  after(:each) do
    Spree::Gateway.all.each { |g| g.destroy }
  end


  context "admin visiting payment methods listing page" do
    it "should display existing payment methods" do
      affirm_gateway =   Spree::Gateway::Affirm.create(
          :name => "Affirm",
          :environment => "test",
          :preferred_server => "sandbox.affirm.com",
          :preferred_api_key => "key",
          :preferred_secret_key => "key",
          :preferred_test_mode => "1"
        )
      click_link "Payment Methods"

      within('table#listing_payment_methods') do
        page.should have_content("Spree::Gateway::Affirm")
      end
    end
  end

  context "create affirm payment method" do
    it "should display existing payment methods" do
      click_link "Payment Methods"
      click_link "admin_new_payment_methods_link"
      page.should have_content("New Payment Method")
      fill_in "payment_method_name", :with => "affirm_gateway"
      fill_in "payment_method_description", :with => "affirm desc"
      select "Spree::Gateway::Affirm", :from => "gtwy-type"
      click_button "Create"
      page.should have_content("successfully created!")
      fill_in "gateway_affirm_preferred_api_key", :with => "APIKEY"
      fill_in "gateway_affirm_preferred_secret_key", :with => "SECRETKEY"
      click_button "Update"
      page.should have_content("successfully updated!")
      gateway = Spree::Gateway.find_by_name("affirm_gateway")
      gateway.preferred_api_key.should eql "APIKEY"
    end

  end
end
