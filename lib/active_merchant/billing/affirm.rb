module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class Affirm < Gateway
      self.supported_countries = %w(US)
      self.default_currency = 'USD'
      self.money_format = :cents

      def initialize(options = {})
          requires!(options, :api_key, :secret_key, :server)
          @api_key = options[:api_key]
          @secret_key = options[:secret_key]
          super
      end

      def set_transaction(transaction_id)
          @transaction_id = transaction_id
      end

      def authorize(money, affirm_source, options = {})
        # [wipn] has affirm_source.token changed?
        result = commit(:post, "", {"transaction_id"=>affirm_source.token}, options, true)
        return result unless result.success?

        ::Rails.logger.info("[Affirm] amount(money).to_i: #{amount(money).to_i}, result.params[\"amount\"].to_i: #{result.params["amount"].to_i}")

        if amount(money).to_i != result.params["amount"].to_i
          ::Rails.logger.error('[spree_affirm] Auth amount does not match charge amount')
          return Response.new(false,
                              "Auth amount does not match charge amount",
                              result.params
                             )
        elsif result.params["pending"].to_s != "true"
          ::Rails.logger.error('[spree_affirm] Error authorizing charge')
          return Response.new(false,
                              "There was an error authorizing this Charge",
                              result.params
                             )
        end
        result
      end

      # To create a charge on a card or a token, call
      #
      #   purchase(money, card_hash_or_token, { ... })
      #
      # To create a charge on a customer, call
      #
      #   purchase(money, nil, { :customer => id, ... })
      def purchase(money, affirm_source, options = {})
          result = authorize(money, affirm_source, options)
          return result unless result.success?
          capture(money, @transaction_id, options)
      end

      def capture(money, charge_source, options = {})
        post = {:amount => amount(money)}
        set_transaction(charge_source)
        result = commit(:post, "#{@transaction_id}/capture", post, options)
        return result unless result.success?

        if amount(money).to_i != result.params["amount"].to_i
          ::Rails.logger.error('[spree_affirm] Capture amount does not match charge amount')
          return Response.new(false,
                "Capture amount does not match charge amount",
                result.params
                )
        end
        result
      end

      def void(charge_source, options = {})
        set_transaction(charge_source)
        commit(:post, "#{@transaction_id}/void", {}, options)
      end

      def refund(money, charge_source, options = {})
        post = {:amount => amount(money)}
        set_transaction(charge_source)
        commit(:post, "#{@transaction_id}/refund", post, options)
      end

      def credit(money, charge_source, options = {})
          set_transaction(charge_source)
          return Response.new(true ,
                       "Credited Zero amount",
                       {},
                       :authorization => @transaction_id,
                      ) unless money > 0
          refund(money, charge_source, options)
      end

      def root_url
        "#{root_api_url}transactions/"
      end

      def root_api_url
        "https://#{@options[:server]}/api/v2/"
      end

      def headers
          {
              "Content-Type" => "application/json",
              "Authorization" => "Basic " + Base64.encode64(@api_key.to_s + ":" + @secret_key.to_s).gsub(/\n/, '').strip,
              "User-Agent" => "Affirm/v2 ActiveMerchantBindings",
          }
      end

      def parse(body)
        JSON.parse(body)
      end

      def post_data(params)
        return nil unless params
        params.to_json
      end

      def response_error(raw_response)
        begin
          parse(raw_response)
        rescue JSON::ParserError
          json_error(raw_response)
        end
      end

      def json_error(raw_response)
        msg = 'Invalid response.  Please contact affirm if you continue to receive this message.'
        msg += "  (The raw response returned by the API was #{raw_response.inspect})"
        {
          "error" => {
            "message" => msg
          }
        }
      end

      def get_checkout(transaction_id)
        _url           = root_api_url + "checkout/#{transaction_id}"
        _raw_response  = ssl_request :get, _url, nil, headers

        parse(_raw_response)
      end

      def commit(method, url, parameters=nil, options = {}, ret_charge=false)
          raw_response = response = nil
          success = false
          begin
              raw_response = ssl_request(method, root_url + url, post_data(parameters), headers)
              response = parse(raw_response)
              success = !response.key?("status_code") && (!ret_charge || response.key?("id"))
          rescue ResponseError => e
              raw_response = e.response.body
              response = response_error(raw_response)
          rescue JSON::ParserError
              response = json_error(raw_response)
          end

          if success && ret_charge
              @transaction_id = response["id"]
          end
          Response.new(success,
                       success ? "Transaction approved" : response["message"],
                       response,
                       :authorization => @transaction_id,
                      )
      end
    end
  end
end
