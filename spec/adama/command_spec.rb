require 'spec_helper'
require_relative 'validator_examples'
require_relative 'command_examples'

RSpec.describe Adama::Command do
  include_examples :validator_base
  include_examples :command_base
end
