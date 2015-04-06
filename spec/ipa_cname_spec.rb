require 'spec_helper'

describe CloudFormation::CustomResource::Router do
  let(:request) do
    {
      'RequestType' => 'Create',
      'TopicArn' => 'arn:aws:sns:us-west-2:841111111111:topic2',
      'ResponseURL' => 'https://cloudformation-custom-resource-response-bogus',
      'StackId' => 'arn:aws:cloudformation:us-west-2:841111111111:stack/chh-junk6/d7cad5a0-d882-11e4',
      'RequestId' => '82a63133-4e23-4736-ad8b-5c71e6bcfdf6',
      'LogicalResourceId' => 'TestResource',
      'ResourceType' => 'Custom::IPA-CNAME',
      'ResourceProperties' => {
        'ServiceToken' => 'arn:aws:sns:us-west-2:841194180831:topic2',
        'aaa' => 'bbb'
      }
    }
  end

  subject{ CloudFormation::CustomResource::Router.default_router }

  context '#get_handle' do
    it 'the default router is wired up to process requests for Custom::IPA-CNAME' do
      expect(subject.get_handler request).to be_an_instance_of CloudFormation::CustomResource::IPA::CNAME
    end
  end
end
