# frozen_string_literal: true

require "jwt"
require "jose"

require_relative "jwks_provider/version"
require_relative "jwks_provider/json_web_key"

module JwksProvider
  class << self
    attr_accessor :app_name
  end
end
