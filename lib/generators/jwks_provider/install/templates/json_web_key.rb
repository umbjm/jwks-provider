# frozen_string_literal: true

module JsonWebKey
  extend ActiveSupport::Concern

  included do
    before_action :load_jwks
  end

  private

  def load_jwks
    @jwks ||= JwksProvider::KeySet.for(Rails.env)
  end

  def current_jwks
    @jwks
  end

  def verify_jwt(token)
    JwksProvider::KeySet.verify_jwt(token, Rails.env)
  end
end
