module Affirm
  class AddressValidator
    def self.normalize_affirm_address(affirm_address_details)
      _address_mapping = {
        "city"         => 'city',
        "street1"      => 'line1',
        "street2"      => 'line2',
        "postal_code"  => 'zipcode',
        "region1_code" => 'state',
        "country_code" => 'country'
      }

      _address_mapping.each do |key, mapped_key|

        unless affirm_address_details[key].present?
          affirm_address_details[key] = affirm_address_details[mapped_key]
        end

      end

      affirm_address_details
    end

  end
end
