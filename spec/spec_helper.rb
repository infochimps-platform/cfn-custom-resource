if ENV['CFN_COV']
  require 'simplecov'
  SimpleCov.start do
    add_group 'Specs',   'spec/'
    add_group 'Library', 'lib/'
  end
end

require 'cfn-custom-resource'
