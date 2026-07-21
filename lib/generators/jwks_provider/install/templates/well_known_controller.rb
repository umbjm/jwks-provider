# frozen_string_literal: true

class WellKnownController < ApplicationController
  include JwksProvider::JsonWebKey

  def jwks
    render json: keys_set
  end
end
