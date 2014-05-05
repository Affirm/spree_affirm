require 'spec_helper'

describe "Affirm checkout" do
  let!(:country) { create(:country, :states_required => true) }
  let!(:state) { create(:state, :country => country) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:stock_location) { create(:stock_location) }
  let!(:check_payment) {create(:check_payment_method, :environment => 'test') }
  let!(:mug) { create(:product, :name => "RoR Mug") }
  let!(:user) {create(:user, :password => "123456", :password_confirmation => "123456")}
  let!(:affirm_payment_gateway) do
    Spree::Gateway::Affirm.create(
      :name => "Affirm",
      :environment => "test"
    )
  end

  let!(:zone) { create(:zone) }
  context "visitor makes checkout as guest without registration" do

    context "full checkout" do
      before do
        mug.shipping_category = shipping_method.shipping_categories.first
        image = File.open(File.expand_path('../../fixtures/thinking-cat.jpg', __FILE__))
        mug.images.create!(:attachment => image)
        mug.images.create!(:attachment => image)
        mug.save!
        visit spree.root_path
        first("#products a").click
        click_button "add-to-cart-button"
        click_button "Checkout"
        fill_in "spree_user_email", :with => user.email
        fill_in "spree_user_password", :with => user.password
        click_button "Login"
      end

      it "returns an error without api key", :js => true do
        fill_in_address

        click_button "Save and Continue"
        click_button "Save and Continue"
        page.should have_content("Affirm")
        within_frame(find("#affirm_checkout_button")) do
          click_link "affirm_button_link"
        end
        within_frame(find("#affirm_error_screen")) do
          page.should have_content("Invalid Request")
        end
      end

    end
  end

  def fill_in_address
    address = "order_bill_address_attributes"
    fill_in "#{address}_firstname", :with => "Ryan"
    fill_in "#{address}_lastname", :with => "Bigg"
    fill_in "#{address}_address1", :with => "143 Swan Street"
    fill_in "#{address}_city", :with => "Richmond"
    select "United States of America", :from => "#{address}_country_id"
    select "Alabama", :from => "#{address}_state_id"
    fill_in "#{address}_zipcode", :with => "12345"
    fill_in "#{address}_phone", :with => "(555) 555-5555"
  end
end
