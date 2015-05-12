def BASE_CHECKOUT_DETAILS
  {
    "merchant"=> {
      "public_api_key"=> "PPPPPPPPPPPPPPP",
      "user_cancel_url"=> "http=>//google.com/cancel",
      "user_confirmation_url"=> "http=>//google.com/confirm",
      "name"=> "Test Merchant"
    },
    "tax_amount"=> 0,
    "billing"=> {
      "address"=> {
        "city"=> "San Francisco",
        "street1"=> "12345 Main",
        "street2"=> "300",
        "region1_code"=> "AL",
        "postal_code"=> "55555",
        "country_code"=> "USA",
        "for_billing"=> true,
        "validation_source"=> 3
      },
      "email"=> "test@affirm.com",
      "name"=> {
        "for_billing"=> true,
        "last"=> "Doe",
        "first"=> "John"
      }
    },
    "items"=> {
      "xxx-xx-xxx-x"=> {
        "sku"=> "xxx-xx-xxx-x",
        "item_url"=> "http=>//google.com/products/the-blue-hat",
        "display_name"=> "The Blue Hat",
        "unit_price"=> 85000,
        "qty"=> 1,
        "item_type"=> "physical",
        "item_image_url"=> "http=>//google.com/products/6/large/the-blue-hat"
      }
    },
    "shipping"=> {
      "name"=> {
        "last"=> "Doe",
        "first"=> "John"
      },
      "address"=> {
        "city"=> "San Francisco",
        "street1"=> "12345 Main Street",
        "street2"=> "300",
        "region1_code"=> "AL",
        "postal_code"=> "94110",
        "country_code"=> "USA",
        "validation_source"=> 3
      }
    },
    "checkout_id"=> "S123123-456",
    "currency"=> "USD",
    "meta"=> {
      "release"=> "true",
      "user_timezone"=> "America/Los_Angeles",
      "__affirm_tracking_uuid"=> "97570a41-cd07-4f52-8869-46c6d2588407"
    },
    "discount_code"=> "",
    "misc_fee_amount"=> 0,
    "shipping_type"=> "Free National UPS",
    "config"=> {
      "financial_product_key"=> "XXXXXXXXXXXXXXX",
      "financial_product_type"=> "splitpay",
      "required_billing_fields"=> [
        "name",
        "address",
        "email"
      ]
    },
    "api_version"=> "v2",
    "shipping_amount"=> 0
  }
end

FactoryGirl.define do
  factory :affirm_checkout, class: Spree::AffirmCheckout do
    token "12345678910"
    association(:payment_method, factory: :affirm_payment_method)
    association(:order, factory: :order_with_line_items)


    transient do
      stub_details true
      product_key_mismatch false
      shipping_address_mismatch false
      billing_address_mismatch false
      alternate_billing_address_format false
      billing_address_full_name false
      billing_email_mismatch false
      extra_line_item false
      missing_line_item false
      quantity_mismatch false
      price_mismatch false
      full_name_case_mismatch false
    end

    after(:build) do |checkout, evaluator|

      _details = BASE_CHECKOUT_DETAILS()

      # product keys
      unless evaluator.product_key_mismatch
        _details['config']['financial_product_key'] = checkout.payment_method.preferred_product_key
      end

      # case mismatch
      unless evaluator.full_name_case_mismatch
        _details['billing']['name'] = {
          "full" => checkout.order.bill_address.firstname.upcase + " " +
                    checkout.order.bill_address.lastname.upcase
        }
      end

      # shipping address
      unless evaluator.shipping_address_mismatch
        _details['shipping'] = {
          "name" => {
            "first" => checkout.order.ship_address.firstname,
            "last"  => checkout.order.ship_address.lastname
          },
          "address"=> {
            "city"=> checkout.order.ship_address.city,
            "street1"=> checkout.order.ship_address.address1,
            "street2"=> checkout.order.ship_address.address2,
            "region1_code"=> checkout.order.ship_address.state.abbr,
            "postal_code"=> checkout.order.ship_address.zipcode,
            "country_code"=> checkout.order.ship_address.country.iso3
          }
        }
      end

      # billing address
      unless evaluator.billing_address_mismatch
        _details["billing"] = {
          "email" => "joe@schmoe.com",
          "name" => {
            "first" => checkout.order.bill_address.firstname,
            "last"  => checkout.order.bill_address.lastname
          },
          "address"=> {
            "city"=> checkout.order.bill_address.city,
            "street1"=> checkout.order.bill_address.address1,
            "street2"=> checkout.order.bill_address.address2,
            "region1_code"=> checkout.order.bill_address.state.abbr,
            "postal_code"=> checkout.order.bill_address.zipcode,
            "country_code"=> checkout.order.bill_address.country.iso3
          }
        }
      end

      # use alternate format for billing address
      if evaluator.alternate_billing_address_format
        _details['billing']["address"] = {
          "city" => _details['billing']["address"]["city"],
          "line1"=> _details['billing']["address"]["street1"],
          "line2"=> _details['billing']["address"]["street2"],
          "state"=> _details['billing']["address"]["postal_code"],
          "zipcode"=> _details['billing']["address"]["region1_code"],
          "country"=> _details['billing']["address"]["country_code"]
        }
      end

      # use name.full instead of first/last
      if evaluator.billing_address_full_name
        _details['billing']['name'] = {
          'full' => "#{_details['billing']['name']['first']} #{_details['billing']['name']['last']}"
        }
      end


      # billing email
      unless evaluator.billing_email_mismatch
        _details["billing"]["email"] = checkout.order.email
      end

      # setup items in cart
      _details['items'] = {}
      checkout.order.line_items.each do |item|
        _details['items'][item.variant.sku] = {
          "qty" => item.quantity.to_s,
          "unit_price" => (item.price*100).to_s,
          "display_name" => item.product.name
        }
      end

      if evaluator.extra_line_item
        _details['items']['extra-1-2-3'] = {
          "qty" => "1",
          "unit_price" => "12300",
          "display_name" => "Really cool hat"
        }
      end

      if evaluator.missing_line_item
        _details['items'].delete _details['items'].keys.last
      end

      if evaluator.quantity_mismatch
        _last_item = _details['items'][_details['items'].keys.last]
        _details['items'][_details['items'].keys.last]['qty'] = (_last_item['qty'].to_i + 1).to_s
      end

      if evaluator.price_mismatch
        _last_item = _details['items'][_details['items'].keys.last]
        _details['items'][_details['items'].keys.last]['unit_price'] = 456456
      end

      if evaluator.stub_details
        checkout.stub(details: _details)
      end
    end

  end
end


