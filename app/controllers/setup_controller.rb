class SetupController < ApplicationController
    skip_before_action :verify_authenticity_token

    def register
        device = Device.find_or_create_by(deviceid: params[:deviceid])
        result = device.update(fcmtoken: params[:token]) ? "ok" : "error"

        render json: { "result": result }
    end
end
