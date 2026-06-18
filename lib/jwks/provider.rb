# frozen_string_literal: true

require_relative "provider/version"
require_relative "provider/key_set"

module Jwks
  module Provider
    class Error < StandardError; end
  end
end

JwksProvider = Jwks::Provider
