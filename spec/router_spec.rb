require 'spec_helper'

class TestResourceHandler < CloudFormation::CustomResource::BaseHandler
  resource_types 'Custom::TestType', 'Custom::Test-Type'
end

describe CloudFormation::CustomResource::Router do
  before :each do
    @request = {
      'RequestType' => 'Create',
      'TopicArn' => 'arn:aws:sns:us-west-2:841111111111:topic2',
      'ResponseURL' => 'https://cloudformation-custom-resource-response-bogus',
      'StackId' => 'arn:aws:cloudformation:us-west-2:841111111111:stack/chh-junk6/d7cad5a0-d882-11e4',
      'RequestId' => '82a63133-4e23-4736-ad8b-5c71e6bcfdf6',
      'LogicalResourceId' => 'TestResource',
      'ResourceType' => 'Custom::IPACname',
      'ResourceProperties' => {
        'ServiceToken' => 'arn:aws:sns:us-west-2:841194180831:topic2',
        'aaa' => 'bbb'
      }
    }
    @config = { :test => "test" }
    @router = CloudFormation::CustomResource::Router.default_router
    @router.config = @config
  end

  describe "#singleton" do
    it "creates a router" do
      expect(@router).to be_an_instance_of CloudFormation::CustomResource::Router
    end
  end

  describe "#get_handler" do
    it "returns a default hander for unknown message types" do
      expect( @router.get_handler( @request ) ).to be_an_instance_of CloudFormation::CustomResource::UnknownResourceHandler
    end


    it "returns handlers for registered types" do
      @request['ResourceType'] = "Custom::TestType"
      expect( @router.get_handler( @request ) ).to be_an_instance_of TestResourceHandler

      @request['ResourceType'] = "Custom::Test-Type"
      expect( @router.get_handler( @request ) ).to be_an_instance_of TestResourceHandler
    end

    it "passes its config on to the handlers it builds" do
      @request['ResourceType'] = "Custom::TestType"
      handler = @router.get_handler( @request )

      expect( handler.config[:test] ).to eql("test")
    end
  end
end
