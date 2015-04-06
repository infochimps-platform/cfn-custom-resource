require 'json'
require 'net/http'
require 'cloud-formation/custom-resource/router'

module CloudFormation
  module CustomResource
    class BaseHandler
      attr_accessor :data, :request, :status, :reason, :config

      def initialize(req, config = nil)
        self.request = req
        self.data    = nil
        self.reason  = nil
        self.config = config || {}
      end

      def self.resource_types(*args)
        args.each do |resource_type|
          CloudFormation::CustomResource::Router.default_router.register(resource_type, self)
        end
      end

      def self.is_default_handler(*args)
        CloudFormation::CustomResource::Router.default_router.default_handler = self
      end

      def self.mandatory_parameters(*args)
        self.send(:define_method, '_mparams') do
          return args
        end
      end

      def self.optional_parameters(*args)
        self.send(:define_method, '_oparams') do
          return args
        end
      end

      def requestId
        return request['RequestId']
      end

      def physicalId
        return request['PhysicalResourceId'] || @pId
      end

      def physicalId= pId
        @pId = pId
      end

      def logicalId
        return request['LogicalResourceId']
      end

      def stackId
        return request['StackId']
      end

      def _mparams
        return []
      end

      def _oparams
        return []
      end

      def fail!(message)
        self.reason = message
        self.status = "FAILED"
        return false
      end

      def validate!(properties)
        success = true
        message = ""

        missing_mandatory = _mparams - properties.keys
        unknown_params = properties.keys - _mparams - _oparams - ['ServiceToken']

        if missing_mandatory.length > 0
          success = false
          message += "Missing Mandatory Parameters: " + missing_mandatory.join(", ") + "\n"
        end

        if unknown_params.length > 0
          success = false
          message += "Unknown Parameters: " + unknown_params.join(", ") + "\n"
        end

        unless success
          fail! message
        end

        success
      end

      def process_request
        result = true
        case request['RequestType']
        when 'Create'
          result = create(request['ResourceProperties'])
        when 'Delete'
          result = delete(request['ResourceProperties'])
        when 'Update'
          result = update(request['ResourceProperties'],request['OldResourceProperties'])
        else
          fail! "Unknown request type: #{request['RequestType']}"
        end

        if result
          self.status = "SUCCESS"
        else
          self.status = "FAILED"
          self.reason ||= "Failed to process request."
        end

        result
      end

      def to_hash
        { 'Status'             => status,
          'Reason'             => reason,
          'PhysicalResourceId' => physicalId,
          'LogicalResourceId'  => logicalId,
          'StackId'            => stackId,
          'RequestId'          => requestId,
          'Data'               => data,
        }.reject {|k,v| v.nil?}

      end


      def send_request!
        response = self.to_hash.to_json

        uri = URI.parse(request['ResponseURL'])
        Net::HTTP.start(uri.host) do |http|
          resp = http.send_request('PUT', uri.request_uri, response, {'content-type'=>''})
        end
      end

    end
  end
end
