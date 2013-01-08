require 'rr'
require 'pry'

require_relative '../lib/tee-dub-feature-flags'


RSpec.configure do |config|
  config.mock_with :rr
  # or if that doesn't work due to a version incompatibility
  # config.mock_with RR::Adapters::Rspec
end

class NullObject
  def self.null
    new
  end

  def method_missing( name, args )
    self
  end
end