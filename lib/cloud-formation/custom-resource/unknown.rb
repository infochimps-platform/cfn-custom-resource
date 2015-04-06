module CloudFormation
  module CustomResource
    class UnknownResourceHandler < BaseHandler

      is_default_handler

      def create(properties)
        self.physicalId = "unknown-#{self.requestId}"
        fail! "Unknown Resource Type: #{request['ResourceType']}"
      end

      def update(properties)
        fail! "Unknown Resource Type: #{request['ResourceType']}"
      end

      def delete(properties)
        true
      end

    end
  end
end
