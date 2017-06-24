require 'spec_helper'
require_relative 'command_examples'

RSpec.describe Adama::Command do
  include_examples :command_base
end
