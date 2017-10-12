module Uphold
  module Transports
    class SQS < MessageQueue
      require 'aws-sdk'
      include DateHelper

      def initialize(params)
        super(params)
        @region = params[:region]
        @access_key_id = params[:access_key_id]
        @secret_access_key = params[:secret_access_key]
        @bucket = params[:bucket]
      end


    end
  end
end
