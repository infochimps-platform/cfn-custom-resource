require 'cloud-formation/custom-resource/base-handler'


describe CloudFormation::CustomResource::BaseHandler do
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
    @handler = CloudFormation::CustomResource::BaseHandler.new(@request)
  end

  describe "#new" do
    it "takes a request as a parameter" do
      expect(@handler).to be_an_instance_of CloudFormation::CustomResource::BaseHandler
    end

    it "sets up accessors for important request parameters" do
      expect(@handler.request).to eq(@request)
      expect(@handler.requestId).to eq(@request['RequestId'])
      expect(@handler.stackId).to eq(@request['StackId'])
      expect(@handler.logicalId).to eq(@request['LogicalResourceId'])
    end

    it "allows setting physicalResourceIds if not provided in request" do
      @handler.physicalId = "blah"
      expect(@handler.physicalId).to eq("blah")
    end
  end

  describe "#validate!" do
    it "takes a hash as an argument and returns a boolean" do
      expect(@handler.validate!( {} )).to eql(true)
      expect(@handler.validate!( {'bad' => 'parameter' } )).to eql(false)
    end

    it "allows but does not require the parmeter 'ServiceToken' " do
      expect(@handler.validate!( {} )).to eql(true)
      expect(@handler.validate!( {'ServiceToken' => 'parameter' } )).to eql(true)
    end

    it "generates failure messages for unknown parameters" do
      expect(@handler.validate!( {'bad' => 'parameter' } )).to eql(false)
      expect(@handler.status).to eql('FAILED')
      expect(@handler.reason).to_not be_nil
    end
  end

  describe "#to_hash" do
    it "generates success messages" do
      @handler.status = "SUCCESS"
      @handler.physicalId = 'pid'
      @handler.data = { 'x' => 'y' }

      hash = @handler.to_hash

      expect(hash['Status']).to eql('SUCCESS')
      expect(hash['Reascon']).to be_nil
      expect(hash['PhysicalResourceId']).to eql('pid')
      expect(hash['LogicalResourceId']).to eql(@request['LogicalResourceId'])
      expect(hash['StackId']).to eql(@request['StackId'])
      expect(hash['RequestId']).to eql(@request['RequestId'])
      expect(hash['Data']['x']).to eql('y')
    end
  end


  describe "#fail!" do
    it "returns false" do
      expect(@handler.fail!("message")).to eql(false)
    end

    it "sets handler status to FAILED and the reason field" do
      @handler.fail!("message")
      expect(@handler.status).to eql('FAILED')
      expect(@handler.reason).to eql('message')
    end

  end
end


class DerivedResource < CloudFormation::CustomResource::BaseHandler
  mandatory_parameters 'a', 'b', 'c'
  optional_parameters *%w(x y z)
end

describe DerivedResource do
  before :each do
    @request = {
      'RequestType' => 'Create',
      'TopicArn' => 'arn:aws:sns:us-west-2:841111111111:topic2',
      'ResponseURL' => 'https://cloudformation-custom-resource-response-bogus',
      'StackId' => 'arn:aws:cloudformation:us-west-2:841111111111:stack/chh-junk6/d7cad5a0-d882-11e4',
      'RequestId' => '82a63133-4e23-4736-ad8b-5c71e6bcfdf6',
      'LogicalResourceId' => 'TestResource',
      'ResourceType' => 'Custom::IPACname',
    }
    @handler = DerivedResource.new(@request)
  end

  describe "#mandatory_parameters" do
    it "gets set up by the class definition" do
      expect(@handler._mparams).to eq(['a', 'b', 'c'])
    end
  end

  describe "#optional_parameters" do
    it "gets set up by the class definition" do
      expect(@handler._oparams).to eq(['x', 'y', 'z'])
    end
  end

  describe "#validate!" do
    it "requires mandatory parameters" do
      expect( @handler.validate!( {'a'=>1, 'b'=>1, 'c'=>3 })).to eql(true)
      expect( @handler.validate!( {'b'=>1, 'c'=>'' })).to eql(false)
      expect( @handler.validate!( {'a'=>nil, 'c'=>'' })).to eql(false)
      expect( @handler.validate!( {'a'=>nil, 'b'=>1  })).to eql(false)
    end

    it "allows optional parameters" do
      expect( @handler.validate!( {'a'=>1, 'b'=>1, 'c'=>3, 'z'=>7 })).to eql(true)
      expect( @handler.validate!( {'a'=>1, 'b'=>1, 'c'=>3, 'x'=>"yes" })).to eql(true)
      expect( @handler.validate!( {'a'=>1, 'b'=>1, 'c'=>3, 'y'=>0 })).to eql(true)
    end

  end
end


describe CloudFormation::CustomResource::BaseHandler do
  before :each do
    @request = {
      'RequestType' => 'Delete',
      'TopicArn' => 'arn:aws:sns:us-west-2:841111111111:topic2',
      'ResponseURL' => 'https://cloudformation-custom-resource-response-bogus',
      'StackId' => 'arn:aws:cloudformation:us-west-2:841111111111:stack/chh-junk6/d7cad5a0-d882-11e4',
      'RequestId' => '82a63133-4e23-4736-ad8b-5c71e6bcfdf6',
      'LogicalResourceId' => 'TestResource',
      'PhysicalResourceId'=> 'supplied-pid',
      'ResourceType' => 'Custom::IPACname',
      'ResourceProperties' => {
        'ServiceToken' => 'arn:aws:sns:us-west-2:841194180831:topic2',
        'aaa' => 'bbb'
      }
    }
    @handler = CloudFormation::CustomResource::BaseHandler.new(@request)
  end

  describe "#new" do

    it "sets up accessors for important request parameters" do
      expect(@handler.request).to eq(@request)
      expect(@handler.requestId).to eq(@request['RequestId'])
      expect(@handler.stackId).to eq(@request['StackId'])
      expect(@handler.logicalId).to eq(@request['LogicalResourceId'])
      expect(@handler.physicalId).to eq(@request['PhysicalResourceId'])
    end

    it "does not allow setting physicalResourceIds when provided in request" do
      @handler.physicalId = "blah"
      expect(@handler.physicalId).to eq(@request['PhysicalResourceId'])
    end
  end
end
