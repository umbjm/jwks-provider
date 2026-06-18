# frozen_string_literal: true

class JwksController < ApplicationController
  include JsonWebKey

  def index
    render json: sig_key_set
  end
end
