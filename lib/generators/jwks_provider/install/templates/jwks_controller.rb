# frozen_string_literal: true

class JwksController < ApplicationController
  include JwksProvider::JsonWebKey

  def index
    render json: keys_set
  end
end
