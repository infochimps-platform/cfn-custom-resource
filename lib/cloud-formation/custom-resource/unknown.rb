module CloudFormation
  module CustomResource
    class UnknownResourceHandler < BaseHandler

      is_default_handler

      def create
        self.physicalId = "unknown-#{self.requestId}"
        fail! "Unknown Resource Type: #{request['ResourceType']}"
      end

      def update
        fail! "Unknown Resource Type: #{request['ResourceType']}"
      end

      def delete
        true
      end

    end
  end
end
