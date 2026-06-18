# frozen_string_literal: true

class JwksController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false
  skip_before_action :authenticate_user!, raise: false

  def index
    render json: JwksProvider::KeySet.public_jwks(Rails.env)
  end
end
