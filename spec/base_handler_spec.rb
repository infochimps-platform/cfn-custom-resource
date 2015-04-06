require 'spec_helper'

describe CloudFormation::CustomResource::BaseHandler do
  let(:request) do
    {
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
  end

  subject{ CloudFormation::CustomResource::BaseHandler.new request }

  context '#new' do
    it 'takes a request as a parameter' do
      expect(subject).to be_an_instance_of CloudFormation::CustomResource::BaseHandler
    end

    it 'sets up accessors for important request parameters' do
      expect(subject.request).to eq(request)
      expect(subject.requestId).to eq(request['RequestId'])
      expect(subject.stackId).to eq(request['StackId'])
      expect(subject.logicalId).to eq(request['LogicalResourceId'])
    end

    it 'allows setting physicalResourceIds if not provided in request' do
      subject.physicalId = 'blah'
      expect(subject.physicalId).to eq('blah')
    end
  end

  context '#validate!' do
    it 'takes a hash as an argument and returns a boolean' do
      expect(subject.validate!({})).to eql(true)
      expect(subject.validate!('bad' => 'parameter')).to eql(false)
    end

    it "allows but does not require the parameter 'ServiceToken'" do
      expect(subject.validate!('ServiceToken' => 'parameter')).to eql(true)
    end

    it 'generates failure messages for unknown parameters' do
      expect(subject.validate!('bad' => 'parameter')).to eql(false)
      expect(subject.status).to eql('FAILED')
      expect(subject.reason).to match(/unknown parameters/i)
    end
  end

  context '#to_hash' do
    it 'generates success messages' do
      subject.status = 'SUCCESS'
      subject.physicalId = 'pid'
      subject.data = { 'x' => 'y' }

      result = subject.to_hash

      expect(result['Status']).to eql('SUCCESS')
      expect(result['Reascon']).to be_nil
      expect(result['PhysicalResourceId']).to eql('pid')
      expect(result['LogicalResourceId']).to eql(request['LogicalResourceId'])
      expect(result['StackId']).to eql(request['StackId'])
      expect(result['RequestId']).to eql(request['RequestId'])
      expect(result['Data']['x']).to eql('y')
    end
  end

  context '#fail!' do
    it 'returns false' do
      expect(subject.fail! 'message').to eql(false)
    end

    it 'sets handler status to FAILED and the reason field' do
      subject.fail! 'message'
      expect(subject.status).to eql('FAILED')
      expect(subject.reason).to eql('message')
    end
  end
end

class DerivedResource < CloudFormation::CustomResource::BaseHandler
  mandatory_parameters 'a', 'b', 'c'
  optional_parameters 'x', 'y', 'z'
end

describe DerivedResource do
  let(:request) do
    {
      'RequestType' => 'Create',
      'TopicArn' => 'arn:aws:sns:us-west-2:841111111111:topic2',
      'ResponseURL' => 'https://cloudformation-custom-resource-response-bogus',
      'StackId' => 'arn:aws:cloudformation:us-west-2:841111111111:stack/chh-junk6/d7cad5a0-d882-11e4',
      'RequestId' => '82a63133-4e23-4736-ad8b-5c71e6bcfdf6',
      'LogicalResourceId' => 'TestResource',
      'ResourceType' => 'Custom::IPACname'
    }
  end

  subject{ DerivedResource.new request }

  context '#mandatory_parameters' do
    it 'gets set up by the class definition' do
      expect(subject._mparams).to eq(%w(a b c))
    end
  end

  context '#optional_parameters' do
    it 'gets set up by the class definition' do
      expect(subject._oparams).to eq(%w(x y z))
    end
  end

  context '#validate!' do
    it 'requires mandatory parameters' do
      expect(subject.validate!('a' => 1, 'b' => 1, 'c' => 3)).to eql(true)
      expect(subject.validate!('b' => 1, 'c' => '')).to eql(false)
      expect(subject.validate!('a' => nil, 'c' => '')).to eql(false)
      expect(subject.validate!('a' => nil, 'b' => 1)).to eql(false)
    end

    it 'allows optional parameters' do
      expect(subject.validate!('a' => 1, 'b' => 1, 'c' => 3, 'z' => 7)).to eql(true)
      expect(subject.validate!('a' => 1, 'b' => 1, 'c' => 3, 'x' => 'yes')).to eql(true)
      expect(subject.validate!('a' => 1, 'b' => 1, 'c' => 3, 'y' => 0)).to eql(true)
    end
  end
end

describe CloudFormation::CustomResource::BaseHandler do
  let(:request) do
    {
      'RequestType' => 'Delete',
      'TopicArn' => 'arn:aws:sns:us-west-2:841111111111:topic2',
      'ResponseURL' => 'https://cloudformation-custom-resource-response-bogus',
      'StackId' => 'arn:aws:cloudformation:us-west-2:841111111111:stack/chh-junk6/d7cad5a0-d882-11e4',
      'RequestId' => '82a63133-4e23-4736-ad8b-5c71e6bcfdf6',
      'LogicalResourceId' => 'TestResource',
      'PhysicalResourceId' => 'supplied-pid',
      'ResourceType' => 'Custom::IPACname',
      'ResourceProperties' => {
        'ServiceToken' => 'arn:aws:sns:us-west-2:841194180831:topic2',
        'aaa' => 'bbb'
      }
    }
  end

  subject{ CloudFormation::CustomResource::BaseHandler.new request }

  context '#new' do
    it 'sets up accessors for important request parameters' do
      expect(subject.request).to eq(request)
      expect(subject.requestId).to eq(request['RequestId'])
      expect(subject.stackId).to eq(request['StackId'])
      expect(subject.logicalId).to eq(request['LogicalResourceId'])
      expect(subject.physicalId).to eq(request['PhysicalResourceId'])
    end

    it 'does not allow setting physicalResourceIds when provided in request' do
      subject.physicalId = 'blah'
      expect(subject.physicalId).to eq(request['PhysicalResourceId'])
    end
  end
end
