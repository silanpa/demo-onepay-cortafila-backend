class TransactionController < ApplicationController
    skip_before_action :verify_authenticity_token
    layout "transaction"

    def create
      cart = Transbank::Onepay::ShoppingCart.new params[:items].as_json
      channel = Transbank::Onepay::Channel::MOBILE

      @transaction_creation_response = Transbank::Onepay::Transaction.create(shopping_cart: cart, channel: channel).to_h

      device = Device.find_by_deviceid(params[:deviceid])
      items = cart.items.as_json.map {|item| Item.new(item)}
      ShoppingCart.create(device: device, items: items, ott: @transaction_creation_response["ott"], occ: @transaction_creation_response["occ"], amount: cart.total, external_unique_number: @transaction_creation_response["external_unique_number"])

      render json: {
        responseCode: @transaction_creation_response["response_code"],
        description: @transaction_creation_response["description"],
        occ: @transaction_creation_response["occ"],
        ott: @transaction_creation_response["ott"],
        externalUniqueNumber: @transaction_creation_response["external_unique_number"],
        issuedAt: @transaction_creation_response["issued_at"],
        signature: @transaction_creation_response["signature"],
        amount: cart.total
      }
    end

    def endTransaction
      @status = params["status"]
      @occ = params["occ"]
      @external_unique_number = params["externalUniqueNumber"]

      shopping_cart = ShoppingCart.find_by_occ @occ
      device = shopping_cart.device
      @items = shopping_cart.items

      options = { "data": {
                  "occ": @occ,
                  "status": @status,
                  "external_unique_number": @external_unique_number
              }}

      if @status == "PRE_AUTHORIZED"
        @transaction_commit_response = Transbank::Onepay::Transaction.commit(
        occ: @occ,
        external_unique_number: @external_unique_number
        )

        options[:data][:description] = @transaction_commit_response.description

        puts "refund_params = { amount: #{@transaction_commit_response.amount},
        occ: #{@transaction_commit_response.occ},
        external_unique_number:#{@external_unique_number},
        authorization_code: #{@transaction_commit_response.authorization_code} }

        @refund_response = Transbank::Onepay::Refund.create(refund_params)
        "
        render :voucher
      else
        render :transaction_error
      end

    rescue Transbank::Onepay::Errors::TransactionCommitError => e
      puts e
      render :transaction_error
    ensure
      if device.android?
        fcm = FCM.new(ENV["FCM_TOKEN"])
        response = fcm.send([device.fcmtoken.undump], options) if device.fcmtoken
      elsif device.web?
        push_data_conn = JSON.parse(device.fcmtoken)
        Webpush.payload_send(
          endpoint: push_data_conn["endpoint"],
          message: JSON.generate(options),
          p256dh: push_data_conn["keys"]["p256dh"],
          auth: push_data_conn["keys"]["auth"],
          vapid: {
            subject: "mailto:transbankdevelopers@continuum.cl",
            public_key: ENV["VAPID_PUBLIC_KEY"],
            private_key: ENV["VAPID_PRIVATE_KEY"]
          }
        )
      end
    end
end
