require 'json'
require 'yaml'
require 'heroic/sns'
require 'cfn-custom-resource'

CloudFormation::CustomResource::Router.default_router.config = {
  'cname-keytab'    => '/etc/www/sns.keytab',
  'cname-principal' => 'cfn-dns-resource'
}

class IPAResourceHandler
  def call(env)
    if error = env['sns.error']
      puts "SNS Error: #{error}"
      response(500, 'Error')
    elsif message = env['sns.message']
      request = JSON.parse message.body
      handler = CloudFormation::CustomResource::Router.default_router.get_handler request
      handler.process_request
      puts request.to_yaml
      puts handler.to_hash.to_yaml
      handler.send_request!
      response(200, 'OK')
    else
      [200, { 'Content-Type' => 'text/html' }, []]
    end
  end

  def response(code, text)
    [code, { 'Content-Type' => 'text/plain', 'Content-Length' => text.length.to_s }, [text]]
  end
end

use Rack::Lint
use Heroic::SNS::Endpoint, topics: Proc.new{ true }, auto_confirm: true, auto_unsubscribe: true
use Rack::Lint
run IPAResourceHandler.new
