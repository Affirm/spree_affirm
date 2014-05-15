module Spree
  class AffirmCheckout < ActiveRecord::Base
    attr_accessor :token
    belongs_to :payment_method
    belongs_to :order

    def details
      @details ||= payment_method.provider.get_checkout token
    end

    def valid?
      self.errors.clear
      self.errors['line_items']            = "Checkout Items mismatch" unless valid_products?
      self.errors['billing_email']         = "Email mismatch" unless matching_product_key?
      self.errors['billing_address']       = "billing address mismatch" unless matching_product_key?
      self.errors['shipping_address']      = "shipping address mismatch" unless matching_product_key?
      self.errors['financial_product_key'] = "Financial Product Key mismatch" unless matching_product_key?

      return self.errors.size == 0
    end


    def valid_products?
      # ensure the number of line items matches
      return false if details["items"].size != order.line_items.size

      # iterate through the line items of the checkout
      order.line_items.each do |line_item|

        # check that the line item sku exists in the affirm checkout
        if !(_item = details["items"][line_item.variant.sku])
          self.errors[line_item.variant.sku] = "Line Item not in checkout details"

        # check quantity & price
        elsif _item["qty"].to_i   != line_item.quantity.to_i
          self.errors[line_item.variant.sku] = "Quantity from affirm (#{_item["qty"]}) does not match #{line_item.quantity}"

        elsif _item["unit_price"].to_i != (line_item.price*100).to_i
          self.errors[line_item.variant.sku] = "Price from affirm (#{_item["price"]}) does not match #{(line_item.price*100).to_i}"

        end
      end

      # all products match
      true
    end

    def matching_billing_address?
      check_address_match details["billing"], order.bill_address
    end

    def matching_shipping_address?
      check_address_match details["shipping"], order.ship_address
    end

    def matching_billing_email?
      details["billing"]["email"].nil? or details["billing"]["email"] == order.email
    end

    def matching_product_key?
      details["config"]["financial_product_key"] == payment_method.preferred_product_key
    end

    private

    def check_address_match(affirm_address, spree_address)
      # mapping from affirm address keys to spree address values
      _key_mapping = {
        city:         spree_address["city"],
        street1:      spree_address["address1"],
        street1:      spree_address["address2"],
        postal_code:  spree_address["zipcode"],
        region1_code: spree_address["state"]["abbr"]

      # check that each value from affirm matches the spree address
      }.each do |affirm_key, spree_val|
        return false if affirm_address["address"][affirm_key.to_s].present? and
                        affirm_address["address"][affirm_key.to_s] != spree_val
      end

      # test affirm names with first and last
      if affirm_address["name"]["first"] and affirm_address["name"]["last"]
        return false if affirm_address["name"]["first"] != spree_address.firstname or
                        affirm_address["name"]["last"]  != spree_address.lastname

      # test affirm names with full name
      elsif affirm_address["name"]["full"]
        return false unless affirm_address["name"]["full"].include?(spree_address.firstname) and
                            affirm_address["name"]["full"].include?(spree_address.lastname)
      end

      true
    end

  end
end
